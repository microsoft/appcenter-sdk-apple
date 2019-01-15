#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSOrderedDictionary.h"
#import "MSSerializableObject.h"

/**
 * The data object contains Part B and Part C properties.
 */
@interface MSCSData : NSObject <MSSerializableObject, MSModel>

@property(atomic, copy) NSDictionary *properties;

@end
