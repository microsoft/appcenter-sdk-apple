#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * The Network extension contains network properties.
 */
@interface MSNetExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The network provider.
 */
@property(nonatomic, copy) NSString *provider;

@end
