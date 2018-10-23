#import "MSAppCenterInternal.h"
#import "MSCustomDelegate.h"
#import "MSDelegateForwarder.h"
#import "MSDelegateForwarderPrivate.h"
#import "MSLogger.h"

#import <objc/runtime.h>

static NSString *const kMSCustomSelectorPrefix = @"custom_";
static NSString *const kMSReturnedValueSelectorPart = @"returnedValue:";

static NSHashTable<id<MSCustomDelegate>> *_delegates = nil;
static NSMutableSet<NSString *> *_selectorsToSwizzle = nil;
static NSMutableDictionary<NSString *, NSValue *> *_originalImplementations = nil;
static NSMutableArray<dispatch_block_t> *traceBuffer = nil;
static IMP _originalSetDelegateImp = NULL;
static BOOL _enabled = YES;

// TODO fix class methods and properties needs to be at instance level.
@implementation MSDelegateForwarder

+ (void)initialize {
  traceBuffer = [NSMutableArray new];
}

- (instancetype)init
{
  if ((self = [super init])) {
    //TODO init properties
  }
  return self;
}

#pragma mark - Logging

- (void)addTraceBlock:(void (^)(void))block {
  @synchronized(traceBuffer) {
    if (traceBuffer) {
      static dispatch_once_t onceToken = 0;
      dispatch_once(&onceToken, ^{
        [traceBuffer addObject:^{
          MSLogVerbose([MSAppCenter logTag], @"Start buffering traces.");
        }];
      });
      [traceBuffer addObject:block];
    } else {
      block();
    }
  }
}

- (void)flushTraceBuffer {
  if (traceBuffer) {
    @synchronized(traceBuffer) {
      for (dispatch_block_t traceBlock in traceBuffer) {
        traceBlock();
      }
      [traceBuffer removeAllObjects];
      traceBuffer = nil;
      MSLogVerbose([MSAppCenter logTag], @"Stop buffering traces, flushed.");
    }
  }
}

#pragma mark - Swizzling

- (void)swizzleOriginalDelegate:(NSObject *)originalDelegate {
  IMP originalImp = NULL;
  Class delegateClass = [originalDelegate class];
  SEL originalSelector, customSelector;
  
  // Swizzle all registered selectors.
  for (NSString *selectorString in self.selectorsToSwizzle) {
    originalSelector = NSSelectorFromString(selectorString);
    customSelector = NSSelectorFromString([kMSCustomSelectorPrefix stringByAppendingString:selectorString]);
    originalImp = [self swizzleOriginalSelector:originalSelector withCustomSelector:customSelector originalClass:delegateClass];
    if (originalImp) {
      
      // Save the original implementation for later use.
      self.originalImplementations[selectorString] = [NSValue valueWithBytes:&originalImp objCType:@encode(IMP)];
    }
  }
  [self.selectorsToSwizzle removeAllObjects];
}

- (void)addAppDelegateSelectorToSwizzle:(SEL)selector {
  if (self.enabled) {
    
    // Swizzle only once and only if needed. No selector to swizzle then no swizzling at all.
    static dispatch_once_t appSwizzleOnceToken;
    dispatch_once(&appSwizzleOnceToken, ^{
      self.originalSetDelegateImp = [self swizzleOriginalSelector:@selector(setDelegate:)
                                                                                   withCustomSelector:@selector(custom_setDelegate:)
                                                                                        originalClass:[MSApplication class]];
    });
    
    /*
     * TODO: We could register custom delegate classes and then query those classes if they responds to selector. If so just add that
     * selector to be swizzled. Just make sure it doesn't have an heavy impact on performances.
     */
    [self.selectorsToSwizzle addObject:NSStringFromSelector(selector)];
  }
}

- (IMP)swizzleOriginalSelector:(SEL)originalSelector withCustomSelector:(SEL)customSelector originalClass:(Class)originalClass {
  
  // Replace original implementation
  NSString *originalSelectorStr = NSStringFromSelector(originalSelector);
  Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
  
  // TODO see what's [self class] is returning here.
  IMP customImp = class_getMethodImplementation([self class], customSelector);
  IMP originalImp = NULL;
  BOOL methodAdded = NO;
  BOOL skipped = NO;
  NSString *warningMsg;
  NSString *remediationMsg = @"You need to explicitly call the App Center API from your app delegate implementation.";
  
  // Replace original implementation by the custom one.
  if (originalMethod) {
    originalImp = method_setImplementation(originalMethod, customImp);
  } else if (![originalClass instancesRespondToSelector:originalSelector]) {
    
    // Check for deprecation.
    NSString *deprecatedSelectorStr = self.deprecatedSelectors[originalSelectorStr];
    if (deprecatedSelectorStr && [originalClass instancesRespondToSelector:NSSelectorFromString(deprecatedSelectorStr)]) {
      
      // An implementation for the deprecated selector exists. Don't add the new method, it might eclipse the original implementation.
      warningMsg = [NSString
                    stringWithFormat:@"No implementation found for this selector, though an implementation of its deprecated API '%@' exists.",
                    deprecatedSelectorStr];
    } else {
      
      // Skip this selector if it's deprecated and doesn't have an implementation.
      if ([self.deprecatedSelectors.allValues containsObject:originalSelectorStr]) {
        skipped = YES;
      } else {
        
        /*
         * The original class may not implement the selector (e.g.: optional method from protocol), add the method to the original class and
         * associate it with the custom implementation.
         */
        // TODO see what's [self class] is returning here.
        Method customMethod = class_getInstanceMethod([self class], customSelector);
        methodAdded = class_addMethod(originalClass, originalSelector, customImp, method_getTypeEncoding(customMethod));
      }
    }
  }
  
  /*
   * If class instances respond to the selector but no implementation is found it's likely that the original class is doing message
   * forwarding, in this case we can't add our implementation to the class or we will break the forwarding.
   */
  
  // Validate swizzling.
  if (!skipped) {
    if (!originalImp && !methodAdded) {
      [self addTraceBlock:^{
        NSString *message = [NSString stringWithFormat:@"Cannot swizzle selector '%@' of class '%@'.", originalSelectorStr, originalClass];
        if (warningMsg) {
          MSLogWarning([MSAppCenter logTag], @"%@ %@", message, warningMsg);
        } else {
          MSLogError([MSAppCenter logTag], @"%@ %@", message, remediationMsg);
        }
      }];
    } else {
      [self addTraceBlock:^{
        MSLogDebug([MSAppCenter logTag], @"Selector '%@' of class '%@' is swizzled.", originalSelectorStr, originalClass);
      }];
    }
  }
  return originalImp;
}

#pragma mark - Custom Application

- (void)custom_setDelegate:(id<NSObject>)delegate {
  //TODO We are executing inside the delegate here, the delegate doasn't know about which forwarder to call since we are in the base class.
  
  // Swizzle only once.
  static dispatch_once_t delegateSwizzleOnceToken;
  dispatch_once(&delegateSwizzleOnceToken, ^{
    
    // Swizzle the delegate object before it's actually set.
    [MSAppDelegateForwarder swizzleOriginalDelegate:delegate];
  });
  
  // Forward to the original `setDelegate:` implementation.
  IMP originalImp = MSAppDelegateForwarder.originalSetDelegateImp;
  if (originalImp) {
    ((void (*)(id, SEL, id<MSApplicationDelegate>))originalImp)(self, _cmd, delegate);
  }
}

#pragma mark - Forwarding

- (void)forwardInvocation:(NSInvocation *)invocation {
  @synchronized([self class]) {
    BOOL forwarded = NO;
    BOOL hasReturnedValue = ([NSStringFromSelector(invocation.selector) hasSuffix:kMSReturnedValueSelectorPart]);
    NSUInteger returnedValueIdx = 0;
    void *returnedValuePtr = NULL;
    
    // Prepare returned value if any.
    if (hasReturnedValue) {
      
      // Returned value argument is always the last one.
      returnedValueIdx = invocation.methodSignature.numberOfArguments - 1;
      returnedValuePtr = malloc(invocation.methodSignature.methodReturnLength);
    }
    
    // Forward to delegates executing a custom method.
    for (id<MSCustomApplicationDelegate> delegate in self.delegates) {
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

#pragma mark - Delegates

- (void)addDelegate:(id<MSCustomDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates addObject:delegate];
    }
  }
}

- (void)removeDelegate:(id<MSCustomDelegate>)delegate {
  @synchronized(self) {
    if (self.enabled) {
      [self.delegates removeObject:delegate];
    }
  }
}

#pragma mark - Other

- (BOOL)enabled {
  @synchronized(self) {
    return _enabled;
  }
}

- (void)setEnabled:(BOOL)enabled {
  @synchronized(self) {
    _enabled = enabled;
    if (!enabled) {
      [self.delegates removeAllObjects];
    }
  }
}

#pragma mark - Testing

- (void)reset {
  [self.delegates removeAllObjects];
  [self.originalImplementations removeAllObjects];
  [self.selectorsToSwizzle removeAllObjects];
}

@end
