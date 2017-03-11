#import <Foundation/Foundation.h>

#import "MSLogManager.h"
#import "MSMobileCenter.h"
#import "MSServiceInternal.h"
#import "MobileCenter+Internal.h"

// Persisted storage keys.
static NSString *const kMSInstallIdKey = @"MSInstallId";
static NSString *const kMSMobileCenterIsEnabledKey = @"MSMobileCenterIsEnabled";

@interface MSMobileCenter ()

@property(nonatomic) id<MSLogManager> logManager;
@property(nonatomic) NSMutableArray<NSObject<MSServiceInternal> *> *services;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, copy) NSString *logUrl;
@property(nonatomic, readonly) NSUUID *installId;
@property BOOL sdkConfigured;
@property BOOL enabledStateUpdating;

/**
 * Returns the singleton instance of Mobile Center.
 */
+ (instancetype)sharedInstance;
- (NSString *)logUrl;
- (NSString *)appSecret;

/**
 * Enable or disable the SDK as a whole. In addition to MobileCenter resources, it will also enable or
 * disable all registered services.
 *
 * @param isEnabled YES to enable, NO to disable.
 * @see isEnabled
 */
- (void)setEnabled:(BOOL)isEnabled;

/**
 * Check whether the SDK is enabled or not as a whole.
 *
 * @return YES if enabled, NO otherwise.
 * @see setEnabled:
 */
- (BOOL)isEnabled;

/**
 * Get the log tag for the MobileCenter service.
 *
 * @return A name of logger tag for the MobileCenter service.
 */
+ (NSString *)logTag;

/**
 * Sort the array of services in descending order based on their priority.
 *
 * @return The array of services in descending order.
 */
- (NSArray *)sortServices:(NSArray<Class> *)services;

@end
