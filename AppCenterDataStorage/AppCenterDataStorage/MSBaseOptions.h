#import <Foundation/Foundation.h>

@interface MSBaseOptions : NSObject

/**
 * Device document time-to-live in seconds. Default is one hour.
 */
@property NSInteger deviceTimeToLive;

/**
 * Initialize a BaseOptions object.
 *
 * @param deviceTimeToLive Device document time to live in seconds.
 *
 * @return A BaseOptions instance.
 */
- (instancetype)initWithDeviceTimeToLive:(NSInteger)deviceTimeToLive;

@end
