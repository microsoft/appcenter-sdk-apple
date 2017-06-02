#import "MSAbstractLogInternal.h"
#import <Foundation/Foundation.h>

@interface MSCustomPropertiesLog : MSAbstractLog

/**
 * Key/value pair properties.
 */
@property(nonatomic) NSDictionary<NSString *, NSObject *> *properties;

@end
