#import <objc/runtime.h>

#import "MSAppDelegate.h"
#import "MSAppDelegateForwarderPrivate.h"
#import "MSLogger.h"
#import "MSMobileCenterInternal.h"
#import "MSUtility+Application.h"

// Enum used to represent all kind of executors running the completion handler.
typedef NS_OPTIONS(NSUInteger, MSCompletionExecutor) {
  MSCompletionExecutorNone = (1 << 0),
  MSCompletionExecutorOriginal = (1 << 1),
  MSCompletionExecutorCustom = (1 << 2),
  MSCompletionExecutorForwarder = (1 << 3)
};

static NSString *const kMSCustomSelectorPrefix = @"custom_";
static NSString *const kMSReturnedValueSelectorPart = @"returnedValue:";
static NSString *const kMSIsAppDelegateForwarderEnabledKey = @"MobileCenterAppDelegateForwarderEnabled";

// Original selectors with special handling.
static NSString *const kMSDidReceiveRemoteNotificationFetchHandler =
    @"application:didReceiveRemoteNotification:fetchCompletionHandler:";
static NSString *const kMSOpenURLSourceApplicationAnnotation = @"application:openURL:sourceApplication:annotation:";
static NSString *const kMSOpenURLOptions = @"application:openURL:options:";

static NSHashTable<id<MSAppDelegate>> *_delegates = nil;
static NSMutableSet<NSString *> *_selectorsToSwizzle = nil;
static NSDictionary<NSString *, NSString *> *_deprecatedSelectors = nil;
static NSMutableDictionary<NSString *, NSValue *> *_originalImplementations = nil;
static NSMutableArray<dispatch_block_t> *traceBuffer = nil;
static IMP _originalSetDelegateImp = NULL;
static BOOL _enabled = YES;

@implementation MSAppDelegateForwarder

+ (void)initialize {
  traceBuffer = [NSMutableArray new];
}

+ (void)load {

  /*
   * The application starts querying its delegate for its implementation as soon as it is set then may never query
   * again. It means that if the application delegate doesn't implement an optional method of the
   * `UIApplicationDelegate` protocol at that time then that method may never be called even if added later via
   * swizzling. This is why the application delegate swizzling should happen at the time it is set to the application
   * object.
   */
  NSDictionary *appForwarderEnabledNum =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:kMSIsAppDelegateForwarderEnabledKey];
  BOOL appForwarderEnabled = appForwarderEnabledNum ? [((NSNumber *)appForwarderEnabledNum)boolValue] : YES;
  MSAppDelegateForwarder.enabled = appForwarderEnabled;

  // Swizzle `setDelegate:` of Application class.
  if (MSAppDelegateForwarder.enabled) {
    [self addTraceBlock:^{
      MSLogDebug([MSMobileCenter logTag], @"Application delegate forwarder is enabled. It may use swizzling.");
    }];
  } else {
    [self addTraceBlock:^{
      MSLogDebug([MSMobileCenter logTag], @"Application delegate forwarder is disabled. It won't use swizzling.");
    }];
  }
}

+ (instancetype)sharedInstance {
  static MSAppDelegateForwarder *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

#pragma mark - Accessors

+ (NSHashTable<id<MSAppDelegate>> *)delegates {
  return _delegates ?: (_delegates = [NSHashTable weakObjectsHashTable]);
}

+ (void)setDelegates:(NSHashTable<id<MSAppDelegate>> *)delegates {
  _delegates = delegates;
}

+ (NSMutableSet<NSString *> *)selectorsToSwizzle {
  return _selectorsToSwizzle ?: (_selectorsToSwizzle = [NSMutableSet new]);
}

+ (NSDictionary<NSString *, NSString *> *)deprecatedSelectors {
  if (!_deprecatedSelectors) {
#if TARGET_OS_OSX
    _deprecatedSelectors = @{};
#else
    _deprecatedSelectors = @{kMSOpenURLOptions : kMSOpenURLSourceApplicationAnnotation};
#endif
  }
  return _deprecatedSelectors;
}

+ (NSMutableDictionary<NSString *, NSValue *> *)originalImplementations {
  return _originalImplementations ?: (_originalImplementations = [NSMutableDictionary new]);
}

+ (void)addTraceBlock:(void (^)())block {
  @synchronized(traceBuffer) {
    if (traceBuffer) {
      static dispatch_once_t onceToken = 0;
      dispatch_once(&onceToken, ^{
        [traceBuffer addObject:^{
          MSLogVerbose([MSMobileCenter logTag], @"Start buffering traces.");
        }];
      });
      [traceBuffer addObject:block];
    } else {
      block();
    }
  }
}

+ (IMP)originalSetDelegateImp {
  return _originalSetDelegateImp;
}

+ (void)setOriginalSetDelegateImp:(IMP)originalSetDelegateImp {
  _originalSetDelegateImp = originalSetDelegateImp;
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

+ (void)addDelegate:(id<MSAppDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates addObject:delegate];
    }
  }
}

+ (void)removeDelegate:(id<MSAppDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates removeObject:delegate];
    }
  }
}

#pragma mark - Swizzling

+ (void)swizzleOriginalDelegate:(id<MSOriginalAppDelegate>)originalDelegate {
  IMP originalImp = NULL;
  Class delegateClass = [originalDelegate class];
  SEL originalSelector, customSelector;

  // Swizzle all registered selectors.
  for (NSString *selectorString in self.selectorsToSwizzle) {
    originalSelector = NSSelectorFromString(selectorString);
    customSelector = NSSelectorFromString([kMSCustomSelectorPrefix stringByAppendingString:selectorString]);
    originalImp =
        [self swizzleOriginalSelector:originalSelector withCustomSelector:customSelector originalClass:delegateClass];
    if (originalImp) {

      // Save the original implementation for later use.
      self.originalImplementations[selectorString] = [NSValue valueWithBytes:&originalImp objCType:@encode(IMP)];
    }
  }
  [self.selectorsToSwizzle removeAllObjects];
}

+ (IMP)swizzleOriginalSelector:(SEL)originalSelector
            withCustomSelector:(SEL)customSelector
                 originalClass:(Class)originalClass {

  // Replace original implementation
  NSString *originalSelectorStr = NSStringFromSelector(originalSelector);
  Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
  IMP customImp = class_getMethodImplementation(self, customSelector);
  IMP originalImp = NULL;
  BOOL methodAdded = NO;
  BOOL skipped = NO;
  NSString *warningMsg;
  NSString *remediationMsg = @"You need to explicitly call the Mobile Center API"
                             @" from your app delegate implementation.";

  // Replace original implementation by the custom one.
  if (originalMethod) {
    originalImp = method_setImplementation(originalMethod, customImp);
  } else if (![originalClass instancesRespondToSelector:originalSelector]) {

    // Check for deprecation.
    NSString *deprecatedSelectorStr = self.deprecatedSelectors[originalSelectorStr];
    if (deprecatedSelectorStr &&
        [originalClass instancesRespondToSelector:NSSelectorFromString(deprecatedSelectorStr)]) {

      /*
       * An implementation for the deprecated selector exists. Don't add the new method, it might eclipse the original
       * implementation.
       */
      warningMsg = [NSString
          stringWithFormat:
              @"No implementation found for this selector, though an implementation of its deprecated API '%@' exists.",
              deprecatedSelectorStr];
    } else {

      // Skip this selector if it's deprecated and doesn't have an implementation.
      if ([self.deprecatedSelectors.allValues containsObject:originalSelectorStr]) {
        skipped = YES;
      } else {

        /*
         * The original class may not implement the selector (e.g.: optional method from protocol),
         * add the method to the original class and associate it with the custom implementation.
         */
        Method customMethod = class_getInstanceMethod(self, customSelector);
        methodAdded = class_addMethod(originalClass, originalSelector, customImp, method_getTypeEncoding(customMethod));
      }
    }
  }

  /*
   * If class instances respond to the selector but no implementation is found it's likely that the original class
   * is doing message forwarding, in this case we can't add our implementation to the class or we will break the
   * forwarding.
   */

  // Validate swizzling.
  if (!skipped) {
    if (!originalImp && !methodAdded) {
      [self addTraceBlock:^{
        NSString *message = [NSString
            stringWithFormat:@"Cannot swizzle selector '%@' of class '%@'.", originalSelectorStr, originalClass];
        if (warningMsg) {
          MSLogWarning([MSMobileCenter logTag], @"%@ %@", message, warningMsg);
        } else {
          MSLogError([MSMobileCenter logTag], @"%@ %@", message, remediationMsg);
        }
      }];
    } else {
      [self addTraceBlock:^{
        MSLogDebug([MSMobileCenter logTag], @"Selector '%@' of class '%@' is swizzled.", originalSelectorStr,
                   originalClass);
      }];
    }
  }
  return originalImp;
}

+ (void)addAppDelegateSelectorToSwizzle:(SEL)selector {
  if (self.enabled) {

    // Swizzle only once and only if needed. No selector to swizzle then no swizzling at all.
    static dispatch_once_t appSwizzleOnceToken;
    dispatch_once(&appSwizzleOnceToken, ^{
      MSAppDelegateForwarder.originalSetDelegateImp =
          [MSAppDelegateForwarder swizzleOriginalSelector:@selector(setDelegate:)
                                       withCustomSelector:@selector(custom_setDelegate:)
#if TARGET_OS_OSX
                                            originalClass:[NSApplication class]];
#else
                                            originalClass:[UIApplication class]];
#endif
    });

    /*
     * TODO: We could register custom delegate classes and then query those classes if they responds to selector.
     * If so just add that selector to be swizzled. Just make sure it doesn't have an heavy impact on performances.
     */
    [self.selectorsToSwizzle addObject:NSStringFromSelector(selector)];
  }
}

#pragma mark - Custom Application

- (void)custom_setDelegate:(id<MSOriginalAppDelegate>)delegate {

  // Swizzle only once.
  static dispatch_once_t delegateSwizzleOnceToken;
  dispatch_once(&delegateSwizzleOnceToken, ^{

    // Swizzle the app delegate before it's actually set.
    [MSAppDelegateForwarder swizzleOriginalDelegate:delegate];
  });

  // Forward to the original `setDelegate:` implementation.
  IMP originalImp = MSAppDelegateForwarder.originalSetDelegateImp;
  if (originalImp) {
    ((void (*)(id, SEL, id<MSOriginalAppDelegate>))originalImp)(self, _cmd, delegate);
  }
}

#pragma mark - Custom UIApplicationDelegate

#if !TARGET_OS_OSX

/*
 * Those methods will never get called but their implementation will be used by swizzling.
 * Those implementations will run within the delegate context. Meaning that `self` will point
 * to the original app delegate and not this forwarder.
 */
- (BOOL)custom_application:(UIApplication *)application
                   openURL:(NSURL *)url
         sourceApplication:(nullable NSString *)sourceApplication
                annotation:(id)annotation {
  BOOL result = NO;
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    result = ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSString *, id))originalImp)(self, _cmd, application, url,
                                                                                       sourceApplication, annotation);
  }

  // Forward to custom delegates.
  return [[MSAppDelegateForwarder sharedInstance] application:application
                                                      openURL:url
                                            sourceApplication:sourceApplication
                                                   annotation:annotation
                                                returnedValue:result];
}

- (BOOL)custom_application:(UIApplication *)application
                   openURL:(nonnull NSURL *)url
                   options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  BOOL result = NO;
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    result =
        ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSDictionary<UIApplicationOpenURLOptionsKey, id> *))originalImp)(
            self, _cmd, application, url, options);
  }

  // Forward to custom delegates.
  return [[MSAppDelegateForwarder sharedInstance] application:application
                                                      openURL:url
                                                      options:options
                                                returnedValue:result];
}
#endif

- (void)custom_application:(MSApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, MSApplication *, NSData *))originalImp)(self, _cmd, application, deviceToken);
  }

  // Forward to custom delegates.
  [[MSAppDelegateForwarder sharedInstance] application:application
      didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)custom_application:(MSApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, MSApplication *, NSError *))originalImp)(self, _cmd, application, error);
  }

  // Forward to custom delegates.
  [[MSAppDelegateForwarder sharedInstance] application:application
      didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)custom_application:(MSApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  IMP originalImp = NULL;

  // Forward to the original delegate.
  [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
  if (originalImp) {
    ((void (*)(id, SEL, MSApplication *, NSDictionary *))originalImp)(self, _cmd, application, userInfo);
  }

  // Forward to custom delegates.
  [[MSAppDelegateForwarder sharedInstance] application:application didReceiveRemoteNotification:userInfo];
}

#if !TARGET_OS_OSX
- (void)custom_application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  __block IMP originalImp = NULL;
  __block UIBackgroundFetchResult actualFetchResult = UIBackgroundFetchResultNoData;
  __block short customHandlerCalledCount = 0;
  __block short customDelegateToCallCount = 0;
  __block MSCompletionExecutor executors = MSCompletionExecutorNone;

  // This handler will be used by all the delegates, it unifies the results and execte the real handler at the end.
  void (^commonCompletionHandler)(UIBackgroundFetchResult, MSCompletionExecutor) =
      ^(UIBackgroundFetchResult fetchResult, MSCompletionExecutor executor) {

        /*
         * As per the Apple dicumentation:
         * https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application
         * The `fetchCompletionHandler` is used to let the app the background time for processing the notification and
         * download any data that will be displayed to the end users when the app will start again. There can only be
         * one `UIBackgroundFetchResult` in the end so there is a need for triage while comparing results from
         * delegates.
         *
         * Priorities are:
         * `UIBackgroundFetchResultNewData`>`UIBackgroundFetchResultFailed`>`UIBackgroundFetchResultNoData`.
         *  - `UIBackgroundFetchResultNewData` means at least one of the delegates did download something successfully.
         *  - `UIBackgroundFetchResultFailed` means there was one/several downloads among the delegates but they failed.
         *  - `UIBackgroundFetchResultNoData` means that none of the delegates had anything to download.
         */
        if (fetchResult == UIBackgroundFetchResultNewData || actualFetchResult == UIBackgroundFetchResultNoData) {
          actualFetchResult = fetchResult;
        }

        // This executor is running its completion handler, remembering it.
        executors = executors | executor;

        // Count all custom executors who already ran their completion handler.
        if (executor == MSCompletionExecutorCustom) {
          customHandlerCalledCount++;
        }

        // Be sure original delegate and/or custom delegates and/or the app forwarder executed their completion handler.
        if ((customHandlerCalledCount == customDelegateToCallCount &&
             (executors & MSCompletionExecutorOriginal || !originalImp)) ||
            (executor == MSCompletionExecutorForwarder)) {
          completionHandler(actualFetchResult);
        }
      };

  // Completion handler dedicated to custom delegates.
  id customCompletionHandler = ^(UIBackgroundFetchResult fetchResult) {
    commonCompletionHandler(fetchResult, MSCompletionExecutorCustom);
  };

  // Block any addition/deletion of custom delegates since delegate count must remain the same.
  @synchronized([MSAppDelegateForwarder class]) {

    // Count how many custom delegates will respond to the selector.
    for (id<MSAppDelegate> delegate in MSAppDelegateForwarder.delegates) {
      if ([delegate respondsToSelector:_cmd]) {
        customDelegateToCallCount++;
      }
    }

    // Forward to the original delegate.
    [MSAppDelegateForwarder.originalImplementations[NSStringFromSelector(_cmd)] getValue:&originalImp];
    if (originalImp) {

      // Completion handler dedicated to the original delegate.
      id originalCompletionHandler = ^(UIBackgroundFetchResult fetchResult) {
        commonCompletionHandler(fetchResult, MSCompletionExecutorOriginal);
      };
      ((void (*)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)))originalImp)(
          self, _cmd, application, userInfo, originalCompletionHandler);
    } else if (customDelegateToCallCount == 0) {

      // There is no one to handle this selector but iOS requires to call the completion handler anyway.
      commonCompletionHandler(UIBackgroundFetchResultNoData, MSCompletionExecutorForwarder);
      return;
    }

    // Forward to custom delegates.
    [[MSAppDelegateForwarder sharedInstance] application:application
                            didReceiveRemoteNotification:userInfo
                                  fetchCompletionHandler:customCompletionHandler];
  }
}
#endif

#pragma mark - Forwarding

- (void)forwardInvocation:(NSInvocation *)invocation {
  @synchronized([self class]) {
    BOOL forwarded = NO;
    BOOL hasReturnedValue = ([NSStringFromSelector(invocation.selector) hasSuffix:kMSReturnedValueSelectorPart]);
    NSUInteger returnedValueIdx = NULL;
    void *returnedValuePtr = NULL;

    // Prepare returned value if any.
    if (hasReturnedValue) {

      // Returned value argument is always the last one.
      returnedValueIdx = invocation.methodSignature.numberOfArguments - 1;
      returnedValuePtr = malloc(invocation.methodSignature.methodReturnLength);
    }

    // Forward to delegates executing a custom method.
    for (id<MSAppDelegate> delegate in [self class].delegates) {
      if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];

        // Chaining return values.
        if (hasReturnedValue) {
          [invocation getReturnValue:returnedValuePtr];
          [invocation setArgument:returnedValuePtr atIndex:returnedValueIdx];
        }
        forwarded = YES;
      }
    }

    // Forward back the original return value if no delegates to receive the message.
    if (hasReturnedValue && !forwarded) {
      [invocation getArgument:returnedValuePtr atIndex:returnedValueIdx];
      [invocation setReturnValue:returnedValuePtr];
    }
    free(returnedValuePtr);
  }
}

#pragma mark - Logging

+ (void)flushTraceBuffer {
  if (traceBuffer) {
    @synchronized(traceBuffer) {
      for (dispatch_block_t traceBlock in traceBuffer) {
        traceBlock();
      }
      [traceBuffer removeAllObjects];
      traceBuffer = nil;
      MSLogVerbose([MSMobileCenter logTag], @"Stop buffering traces, flushed.");
    }
  }
}

#pragma mark - Testing

+ (void)reset {
  [self.delegates removeAllObjects];
  [self.originalImplementations removeAllObjects];
  [self.selectorsToSwizzle removeAllObjects];
}

@end
