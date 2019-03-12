#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

static NSString *const kMSDoubleTypedPropertyType = @"double";

@interface MSDoubleTypedProperty : MSTypedProperty

/**
 * Double property value.
 */
@property(nonatomic) double value;

@end
