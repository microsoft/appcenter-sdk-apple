#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSMockAppDelegate.h"

@implementation MSMockAppDelegate

- (instancetype)init {
  if ((self = [super init])) {
    _originalDelegateValidators = [NSMutableDictionary new];
    _customDelegateValidators = [NSMutableDictionary new];
  }
  return self;
}

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  SEL selector = @selector(application:openURL:sourceApplication:annotation:);
  OriginalOpenURLiOS42Validator validator = self.originalDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, sourceApplication, annotation);
}

#pragma mark - MSAppDelegate

- (BOOL)application:(UIApplication *)app
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation
        returnedValue:(BOOL)returnedValue {
  SEL selector = @selector(application:openURL:sourceApplication:annotation:returnedValue:);
  CustomOpenURLiOS42Validator validator = self.customDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, sourceApplication, annotation, returnedValue);
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  SEL selector = @selector(application:openURL:options:returnedValue:);
  CustomOpenURLiOS9Validator validator = self.customDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, options, returnedValue);
}

@end

#pragma mark - Swizzling

@implementation MSAppDelegateForwarder (MSDistribute)

+ (void)load{
  
  // Register selectors to swizzle for Ditribute.
  [self addAppDelegateSelectorToSwizzle:@selector(application:openURL:options:)];
  [self addAppDelegateSelectorToSwizzle:@selector(application:openURL:sourceApplication:annotation:)];
}

@end

@implementation MSChildMockAppDelegateWithoutImplementation
@end

@implementation MSChildMockAppDelegateWithImplementation

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  return [super application:app openURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - MSAppDelegate

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
      returnedValue:(BOOL)returnedValue {
  return [super application:app openURL:url sourceApplication:sourceApplication annotation:annotation returnedValue:returnedValue];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  return [super application:app openURL:url options:options returnedValue:returnedValue];
}

@end

@implementation MCBaseMockAppDelegateWithoutImplementation

- (instancetype)init {
  if ((self = [super init])) {
    _originalDelegateValidators = [NSMutableDictionary new];
    _customDelegateValidators = [NSMutableDictionary new];
  }
  return self;
}

@end

@implementation MSChildMockAppDelegateWithoutImpInBaseClass

#pragma mark - UIApplication

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  SEL selector = @selector(application:openURL:sourceApplication:annotation:);
  OriginalOpenURLiOS42Validator validator = self.originalDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, sourceApplication, annotation);
}

#pragma mark - MSAppDelegate

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
      returnedValue:(BOOL)returnedValue {
  SEL selector = @selector(application:openURL:sourceApplication:annotation:returnedValue:);
  CustomOpenURLiOS42Validator validator = self.customDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, sourceApplication, annotation, returnedValue);
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
      returnedValue:(BOOL)returnedValue {
  SEL selector = @selector(application:openURL:options:returnedValue:);
  CustomOpenURLiOS9Validator validator = self.customDelegateValidators[NSStringFromSelector(selector)];
  return validator(app, url, options, returnedValue);
}

@end
