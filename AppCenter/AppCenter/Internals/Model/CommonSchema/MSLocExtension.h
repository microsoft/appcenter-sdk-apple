#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * Describes the location from which the event was logged.
 */
@interface MSLocExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Time zone on the device.
 */
@property(nonatomic, copy) NSString *tz;

@end
