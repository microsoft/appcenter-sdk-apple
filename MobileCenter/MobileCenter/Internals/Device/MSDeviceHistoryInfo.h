#import <Foundation/Foundation.h>

@class MSDevice;

/**
 * Model class that is intended to be used to correlate MSDevice to a crash at app relaunch.
 */
@interface MSDeviceHistoryInfo : NSObject <NSCoding>

/**
 * The tOffset that indicates the moment in time for the device history.
 */
@property (nonatomic) NSNumber *tOffset;

/**
 * Instance of MSDivice.
 */
@property (nonatomic) MSDevice *device;

- (instancetype)initWithTOffset:(NSNumber *)tOffset andDevice:(MSDevice *)device;

@end