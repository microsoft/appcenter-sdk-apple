#import "MSTypedProperty.h"

static NSString *const kMSDateTimeTypedPropertyType = @"dateTime";

@interface MSDateTimeTypedProperty : MSTypedProperty

/**
 * Date and time property value.
 */
@property(nonatomic) NSDate *value;

@end
