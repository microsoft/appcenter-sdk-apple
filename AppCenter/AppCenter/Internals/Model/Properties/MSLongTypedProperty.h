#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

@interface MSLongTypedProperty : MSTypedProperty

/**
 * Long property value (64-bit signed integer).
 */
@property(nonatomic) int64_t value;

@end
