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

/**
* Property value.
*/
@property(nonatomic, copy) NSObject *value;

/**
 * Creates an instance with the `type` property set appropriately for string types.
 * @return an instance of MSTypedProperty.
 */
+ (instancetype) stringTypedProperty;

/**
 * Creates an instance with the `type` property set appropriately for long types.
 * @return an instance of MSTypedProperty.
 */
+ (instancetype) longTypedProperty;

/**
 * Creates an instance with the `type` property set appropriately for double types.
 * @return an instance of MSTypedProperty.
 */
+ (instancetype) doubleTypedProperty;

/**
 * Creates an instance with the `type` property set appropriately for bool types.
 * @return an instance of MSTypedProperty.
 */
+ (instancetype) boolTypedProperty;

/**
 * Creates an instance with the `type` property set appropriately for date types.
 * @return an instance of MSTypedProperty.
 */
+ (instancetype) dateTypedProperty;


@end
