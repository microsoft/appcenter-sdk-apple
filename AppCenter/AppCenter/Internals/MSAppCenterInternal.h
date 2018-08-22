#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSAppCenter.h"
#import "MSChannelGroupProtocol.h"
#import "MSServiceInternal.h"

// Persisted storage keys.
static NSString *const kMSInstallIdKey = @"MSInstallId";
static NSString *const kMSAppCenterIsEnabledKey = @"MSAppCenterIsEnabled";

// Name of the environment variable to check for which services should be
// disabled.
static NSString *const kMSDisableVariable = @"APP_CENTER_DISABLE";

// Value that would cause all services to be disabled.
static NSString *const kMSDisableAll = @"All";

@interface MSAppCenter ()

@property(nonatomic) id<MSChannelGroupProtocol> channelGroup;
@property(nonatomic) NSMutableArray<NSObject<MSServiceInternal> *> *services;
@property(nonatomic) NSMutableArray<NSString *> *startedServiceNames;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, copy) NSString *defaultTransmissionTargetToken;
@property(nonatomic, copy) NSString *logUrl;
@property(nonatomic, readonly) NSUUID *installId;
@property BOOL sdkConfigured;
@property BOOL configuredFromApplication;
@property BOOL enabledStateUpdating;

/**
 * Returns the singleton instance of App Center.
 */
+ (instancetype)sharedInstance;
- (NSString *)logUrl;
- (NSString *)appSecret;

/**
 * Enable or disable the SDK as a whole. In addition to AppCenter resources, it
 * will also enable or disable all registered services.
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
 * Get the log tag for the AppCenter service.
 *
 * @return A name of logger tag for the AppCenter service.
 */
+ (NSString *)logTag;

/**
 * Get the group ID for the AppCenter service.
 *
 * @return A storage identifier for the AppCenter service.
 */
+ (NSString *)groupId;

/**
 * Sort the array of services in descending order based on their priority.
 *
 * @return The array of services in descending order.
 */
- (NSArray *)sortServices:(NSArray<Class> *)services;

@end
