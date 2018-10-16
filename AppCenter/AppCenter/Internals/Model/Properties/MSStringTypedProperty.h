#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

@interface MSStringTypedProperty : MSTypedProperty

/**
 * String property value.
 */
@property(nonatomic, copy) NSString *value;

@end
