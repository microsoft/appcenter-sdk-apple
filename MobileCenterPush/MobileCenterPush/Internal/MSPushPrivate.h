#import "MSPush.h"
#import "MSPushDelegate.h"
#import "MSServiceInternal.h"

@interface MSPush ()

@property(nonatomic) id<MSPushDelegate> delegate;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void) resetSharedInstance;

/**
 * Method generate MSPushInstallationLog log and send it 
 *
 * @param token The device token converted to NSString
 */
- (void) sendDeviceToken: (NSString *)token;

/**
 * Method convert device token from NSData* to NSString*
 *
 * @param token The device token
 */
- (NSString *)convertTokenToString:(NSData *)token;

/**
 * Method register notification settings and register application for remote notifications
 */
- (void) registerForRemoteNotifications;

@end
