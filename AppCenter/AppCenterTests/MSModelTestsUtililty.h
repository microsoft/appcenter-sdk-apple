#import "MSDevice.h"
#import <Foundation/Foundation.h>

@interface MSModelTestsUtililty : NSObject

/**
 * Get dummy values for device model.
 * @return Dummy values for device model.
 */
+ (NSDictionary *)deviceDummies;

/**
 * Get a dummy device model.
 * @return A dummy device model.
 */
+ (MSDevice *)dummyDevice;

/**
 * Get dummy values for abstract log.
 * @return Dummy values for abstract log.
 */
+ (NSDictionary *)abstractLogDummies;

/**
 * Populate an abstract log with dummy values.
 * @param log An abstract log to be filled with dummy values.
 */
+ (void)populateAbstractLogWithDummies:(MSAbstractLog *)log;

@end
