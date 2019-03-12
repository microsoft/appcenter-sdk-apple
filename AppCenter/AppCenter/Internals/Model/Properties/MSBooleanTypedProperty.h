#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

static NSString *const kMSBooleanTypedPropertyType = @"boolean";

@interface MSBooleanTypedProperty : MSTypedProperty

/**
 * Boolean property value.
 */
@property(nonatomic) BOOL value;

@end
