#import <Foundation/Foundation.h>

#import "MSTypedProperty.h"

@interface MSDateTimeTypedProperty : MSTypedProperty

/**
 * Date and time property value.
 */
@property(nonatomic) NSDate *value;

@end
