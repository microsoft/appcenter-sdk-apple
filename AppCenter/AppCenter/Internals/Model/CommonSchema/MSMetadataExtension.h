#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * The metadata section contains additional typing/schema-related information for each field in the Part B or Part C payload.
 */
@interface MSMetadataExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Additional typing/schema-related information for each field in the Part B or Part C payload.
 */
@property(atomic, copy) NSDictionary *metadata;

@end
