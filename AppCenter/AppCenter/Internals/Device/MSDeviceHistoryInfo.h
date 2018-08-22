#import <Foundation/Foundation.h>

@class MSDevice;

/**
 * Model class that is intended to be used to correlate MSDevice to a crash at
 * app relaunch.
 */
@interface MSDeviceHistoryInfo : NSObject <NSCoding>

/**
 * The moment in time for the device history.
 */
@property(nonatomic) NSDate *timestamp;

/**
 * Instance of MSDevice.
 */
@property(nonatomic) MSDevice *device;

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                        andDevice:(MSDevice *)device;

@end
