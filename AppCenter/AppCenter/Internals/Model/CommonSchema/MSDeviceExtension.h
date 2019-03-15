#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSDeviceLocalId = @"localId";

/**
 * Device extension contains device information.
 */
@interface MSDeviceExtension : NSObject <MSSerializableObject, MSModel>

@property(nonatomic, copy) NSString *localId;

@end
