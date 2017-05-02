#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "MSAppDelegateForwarderPrivate.h"
#import "MSCustomAppDelegate.h"
#import "MSOriginalAppDelegate.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUtility+Application.h"

static const NSString *kMSOriginalSelectorPrefix = @"ms_original_";
static const NSString *kMSReturnedValueSelectorPart = @"returnedValue:";

static NSHashTable<id<MSCustomAppDelegate>> *_delegates = nil;
static NSMutableArray<NSString *> *_swizzledSelectors = nil;
static BOOL _enabled = YES;

@implementation MSAppDelegateForwarder

#pragma mark - Accessors

+ (NSHashTable<id<MSCustomAppDelegate>> *)delegates {
  return _delegates ?: (_delegates = [NSHashTable weakObjectsHashTable]);
}

+ (void)setDelegates:(NSHashTable<id<MSCustomAppDelegate>> *)delegates {
  _delegates = delegates;
}

+ (NSMutableArray<NSString *> *)swizzledSelectors {
  return _swizzledSelectors ?: (_swizzledSelectors = [NSMutableArray new]);
}

+ (void)setSwizzledSelectors:(NSMutableArray<NSString *> *)swizzledSelectors {
  _swizzledSelectors = swizzledSelectors;
}

+ (BOOL)enabled {
  @synchronized(self) {
    return _enabled;
  }
}

+ (void)setEnabled:(BOOL)enabled {
  @synchronized(self) {
    _enabled = enabled;
    if (!enabled) {
      [self.delegates removeAllObjects];
    }
  }
}

#pragma mark - Delegates

+ (void)registerSwizzlingForDelegate:(id<MSCustomAppDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      unsigned int count;
      NSString *selectorString;
      NSString *appDelegateSelector;

      // Browse methods from delegate and swizzle if needed.
      struct objc_method_description *methods =
          protocol_copyMethodDescriptionList(@protocol(MSCustomAppDelegate), NO, YES, &count);
      for (unsigned int i = 0; i < count; i++) {
        SEL selector = methods[i].name;
        selectorString = NSStringFromSelector(selector);

        // Make sure the delegate implements the selector.
        if ([delegate respondsToSelector:selector]) {
          appDelegateSelector =
              [selectorString substringToIndex:(selectorString.length - kMSReturnedValueSelectorPart.length)];
          [self swizzleSelector:NSSelectorFromString(appDelegateSelector)];
        }
      }
      free(methods);
    }
  }
}

+ (void)addDelegate:(id<MSCustomAppDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates addObject:delegate];
    }
  }
}

+ (void)removeDelegate:(id<MSCustomAppDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates removeObject:delegate];
    }
  }
}

#pragma mark - Swizzling

+ (void)swizzleSelector:(SEL)selector {
  NSString *oldOriginalSelector = NSStringFromSelector(selector);
  NSString *newOriginalSelector;

  // Don't swizzle twice the same selector.
  if (![self.swizzledSelectors containsObject:oldOriginalSelector]) {
    id delegate = [MSUtility sharedAppDelegate];
    Class appDelegateClass = [delegate class];

    // Shared application not always available (i.e.:App extensions).
    if (appDelegateClass) {

      // Capture methods.
      Method originalMethod = class_getInstanceMethod(appDelegateClass, selector);
      Method customMethod = class_getInstanceMethod(self, selector);

      // FIXME: Search super classes if current class doesn't implement the selector. Use respondsToSelector:.

      // Create a new prefixed method to hold the existing implementation.
      newOriginalSelector = [kMSOriginalSelectorPrefix stringByAppendingString:oldOriginalSelector];
      BOOL methodAdded =
          class_addMethod(appDelegateClass, NSSelectorFromString(newOriginalSelector),
                          method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));

      // Replace the original method by the new implementation.
      if (methodAdded || ![delegate respondsToSelector:selector]) {
        class_replaceMethod(appDelegateClass, selector, method_getImplementation(customMethod),
                            method_getTypeEncoding(customMethod));
        [self.swizzledSelectors addObject:oldOriginalSelector];
        MSLogDebug([MSMobileCenter logTag], @"App delegate selector %@ swizzled.", oldOriginalSelector);
      }

      // The new method may not be added (i.e.: in case of conflicts), should be rare as it's prefixed.
      else {
        MSLogError([MSMobileCenter logTag],
                   @"Cannot swizzle selector %@. You will have to explicitly call the coresponding API from "
                   @"Mobile Center in your app delegate implementation.",
                   oldOriginalSelector);
        return;
      }
    }
  }
}

#pragma mark - UIApplicationDelegate

/*
 * Those methods will never get called but their implementation will be used by swizzling.
 * Those implementations will run within the delegate context.
 * Meaning that `self` will point to the original app delegate and not this forwarder.
 */

- (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
    sourceApplication:(nullable NSString *)sourceApplication
           annotation:(id)annotation {
  BOOL result = NO;
  MSAppDelegateForwarder *forwarder = [MSAppDelegateForwarder new];

  // Execute original method if any.
  if ([self respondsToSelector:@selector(ms_original_application:openURL:sourceApplication:annotation:)]) {
    result = [((id<MSOriginalAppDelegate>)self) ms_original_application:app
                                                                openURL:url
                                                      sourceApplication:sourceApplication
                                                             annotation:annotation];
  }

  // Forward method.
  return [forwarder application:app
                        openURL:url
              sourceApplication:sourceApplication
                     annotation:annotation
                  returnedValue:result];
}

- (BOOL)application:(UIApplication *)app
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  BOOL result = NO;

  // Execute original method if any.
  if ([self respondsToSelector:@selector(ms_original_application:openURL:options:)]) {
    result = [((id<MSOriginalAppDelegate>)self) ms_original_application:app openURL:url options:options];
  }

  // Forward method.
  return [[MSAppDelegateForwarder new] application:app openURL:url options:options returnedValue:result];
}

#pragma mark - Forwarding

- (void)forwardInvocation:(NSInvocation *)invocation {
  @synchronized([self class]) {
    BOOL forwarded = NO;

    // Returned value argument is always the last one.
    NSUInteger returnedValueIdx = invocation.methodSignature.numberOfArguments - 1;
    void *returnedValuePtr = malloc(invocation.methodSignature.methodReturnLength);

    // Forward to delegates executing a custom method.
    for (id<MSCustomAppDelegate> delegate in [self class].delegates) {
      if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];

        // Chaining return values.
        [invocation getReturnValue:returnedValuePtr];
        [invocation setArgument:returnedValuePtr atIndex:returnedValueIdx];
        forwarded = YES;
      }
    }

    // Forward back the original return value if no delegates to receive the message.
    if (!forwarded) {
      [invocation getArgument:returnedValuePtr atIndex:returnedValueIdx];
      [invocation setReturnValue:returnedValuePtr];
    }
    free(returnedValuePtr);
  }
}

@end
