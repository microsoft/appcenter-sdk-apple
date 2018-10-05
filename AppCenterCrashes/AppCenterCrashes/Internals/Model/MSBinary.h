#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSSerializableObject.h"

/**
 * Binary (library) definition for any platform.
 */
@interface MSBinary : NSObject <MSSerializableObject>

/**
 * The binary id as UUID string.
 */
@property(nonatomic, copy) NSString *binaryId;

/**
 * The binary's start address.
 */
@property(nonatomic, copy) NSString *startAddress;

/**
 * The binary's end address.
 */
@property(nonatomic, copy) NSString *endAddress;

/**
 * The binary's name.
 */
@property(nonatomic, copy) NSString *name;

/**
 * The path to the binary.
 */
@property(nonatomic, copy) NSString *path;

/**
 * The architecture.
 */
@property(nonatomic, copy) NSString *architecture;

/**
 * CPU primary architecture [optional].
 */
@property(nonatomic) NSNumber *primaryArchitectureId;

/**
 * CPU architecture variant [optional].
 */
@property(nonatomic) NSNumber *architectureVariantId;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
