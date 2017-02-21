#import "MSPush.h"
#import "MSPushDelegate.h"
#import "MSServiceInternal.h"

@interface MSPush ()

@property(nonatomic) id<MSPushDelegate> delegate;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void) resetSharedInstance;

@end
