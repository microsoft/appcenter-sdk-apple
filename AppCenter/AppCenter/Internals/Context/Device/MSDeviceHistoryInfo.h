#import "MSHistoryInfo.h"

@class MSDevice;

/**
 * Model class that correlates MSDevice to a crash at app relaunch.
 */
@interface MSDeviceHistoryInfo : MSHistoryInfo

/**
 * Instance of MSDevice.
 */
@property(nonatomic) MSDevice *device;

/**
 * Initializes a new `MSDeviceHistoryInfo` instance.
 *
 * @param timestamp Timestamp.
 * @param device Device instance.
 */
- (instancetype)initWithTimestamp:(NSDate *)timestamp andDevice:(MSDevice *)device;

@end
