#import "MSDevice.h"

/**
 * Provide and keep track of device log based on collected properties.
 */
@interface MSDeviceTracker : NSObject

/**
 * Current device log.
 */
@property(nonatomic, readonly) MSDevice *device;

@end
