#import <Foundation/Foundation.h>

#import "MSService.h"

/**
 *  Abstraction of services common logic.
 * This class is intended to be subclassed only not instantiated directly.
 */
@interface MSServiceAbstract : NSObject <MSService>
@end
