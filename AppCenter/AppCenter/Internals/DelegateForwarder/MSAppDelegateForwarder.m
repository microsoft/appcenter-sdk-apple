#import "MSAppDelegateForwarder.h"
#import "MSCustomApplicationDelegate.h"
#import "MSUtility+Application.h"

static NSString *const kMSIsAppDelegateForwarderEnabledKey = @"AppCenterAppDelegateForwarderEnabled";

// Original selectors with special handling.
static NSString *const kMSOpenURLSourceApplicationAnnotation = @"application:openURL:sourceApplication:annotation:";
static NSString *const kMSOpenURLOptions = @"application:openURL:options:";

static NSDictionary<NSString *, NSString *> *_deprecatedSelectors = nil;

@implementation MSAppDelegateForwarder

+ (instancetype)sharedInstance {
  static MSAppDelegateForwarder *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

// TODO initialize the instance properties in each subclasses.
//#pragma mark - Accessors
//
//+ (NSHashTable<id<MSCustomApplicationDelegate>> *)delegates {
//  return _delegates ?: (_delegates = [NSHashTable weakObjectsHashTable]);
//}
//
//+ (void)setDelegates:(NSHashTable<id<MSCustomApplicationDelegate>> *)delegates {
//  _delegates = delegates;
//}
//
//+ (NSMutableSet<NSString *> *)selectorsToSwizzle {
//  return _selectorsToSwizzle ?: (_selectorsToSwizzle = [NSMutableSet new]);
//}
//
//+ (NSDictionary<NSString *, NSString *> *)deprecatedSelectors {
//  if (!_deprecatedSelectors) {
//#if TARGET_OS_OSX
//    _deprecatedSelectors = @{};
//#else
//    _deprecatedSelectors = @{kMSOpenURLOptions : kMSOpenURLSourceApplicationAnnotation};
//#endif
//  }
//  return _deprecatedSelectors;
//}
//
//+ (NSMutableDictionary<NSString *, NSValue *> *)originalImplementations {
//  return _originalImplementations ?: (_originalImplementations = [NSMutableDictionary new]);
//}
//
//+ (IMP)originalSetDelegateImp {
//  return _originalSetDelegateImp;
//}
//
//+ (void)setOriginalSetDelegateImp:(IMP)originalSetDelegateImp {
//  _originalSetDelegateImp = originalSetDelegateImp;
//}

#pragma mark - Custom UIApplicationDelegate

#if !TARGET_OS_OSX

/*
 * Those methods will never get called but their implementation will be used by swizzling. Those implementations will run within the
 * delegate context. Meaning that `self` will point to the original app delegate and not this forwarder.
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
    result = ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSString *, id))originalImp)(self, _cmd, application, url, sourceApplication,
                                                                                       annotation);
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
    result = ((BOOL(*)(id, SEL, UIApplication *, NSURL *, NSDictionary<UIApplicationOpenURLOptionsKey, id> *))originalImp)(
        self, _cmd, application, url, options);
  }

  // Forward to custom delegates.
  return [[MSAppDelegateForwarder sharedInstance] application:application openURL:url options:options returnedValue:result];
}
#endif

@end
