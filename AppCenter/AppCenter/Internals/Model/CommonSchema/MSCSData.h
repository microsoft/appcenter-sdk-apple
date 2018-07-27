#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * The metadata section contains additional typing/schema-related information
 * for each field in the Part B or Part C payload.
 */
@interface MSCSData : NSObject <MSSerializableObject, MSModel>

@property(atomic, copy) NSDictionary *properties;

@end
