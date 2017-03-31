#import "MSAbstractLog.h"
#import <Foundation/Foundation.h>

@interface MSCustomPropertiesLog : MSAbstractLog

/**
 * Properties key/value pairs.
 */
@property(nonatomic) NSDictionary<NSString *, NSObject *> *properties;

@end
