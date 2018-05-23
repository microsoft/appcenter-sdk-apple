#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The metadata section contains additional typing/schema-related information for each field in the Part B or Part C payload.
 */
@interface MSCSData : NSObject <MSSerializableObject, MSModel>

@property (atomic, copy) NSMutableDictionary *properties;

@end
