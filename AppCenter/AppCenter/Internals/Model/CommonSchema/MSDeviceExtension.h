#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * Device extension contains device information.
 */
@interface MSDeviceExtension : NSObject <MSSerializableObject, MSModel>

@property(nonatomic, copy) NSString *localId;

@end
