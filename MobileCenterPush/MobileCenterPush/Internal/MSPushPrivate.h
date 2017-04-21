#import "MSPush.h"
#import "MSPushDelegate.h"
#import "MSServiceInternal.h"

@interface MSPush ()

@property(nonatomic) id<MSPushDelegate> delegate;

@property(nonatomic) BOOL pushTokenHasBeenSent;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

/**
 * Method generates MSPushLog log and send it.
 *
 * @param token The push token converted to NSString.
 */
- (void)sendPushToken:(NSString *)token;

/**
 * Method converts NSData to NSString.
 *
 * @param token The push token.
 */
- (NSString *)convertTokenToString:(NSData *)token;

/**
 * Method registers notification settings and an application for remote notifications.
 */
- (void)registerForRemoteNotifications;

@end
