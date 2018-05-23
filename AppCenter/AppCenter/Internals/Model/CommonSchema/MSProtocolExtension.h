#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The Protocol extension contains device specific information. 
 */
@interface MSProtocolExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The device's manufacturer.
 */
@property(nonatomic, copy) NSString *devMake;

/**
 * The device's model.
 */
@property(nonatomic, copy) NSString *devModel;

@end
