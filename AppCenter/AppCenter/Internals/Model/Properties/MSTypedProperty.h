#import <Foundation/Foundation.h>

#import "MSSerializableObject.h"

@interface MSTypedProperty : NSObject <MSSerializableObject>

/**
 * Property type.
 */
@property(nonatomic, copy) NSString *type;

/**
 * Property name.
 */
@property(nonatomic, copy) NSString *name;

@end
