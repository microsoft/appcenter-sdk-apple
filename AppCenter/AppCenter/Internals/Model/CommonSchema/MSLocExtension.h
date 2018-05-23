#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * Describes the location from which the event was logged.
 */
@interface MSLocExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Time zone on the device.
 */
@property(nonatomic, copy) NSString *timezone;

@end
