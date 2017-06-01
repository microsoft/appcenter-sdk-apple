#import "MSAbstractLogInternal.h"
#import "MSLogWithProperties.h"

@interface MSLogWithProperties ()

/**
 * Additional key/value pair parameters.  [optional]
 */
@property(nonatomic) NSDictionary<NSString *, NSString *> *properties;

@end
