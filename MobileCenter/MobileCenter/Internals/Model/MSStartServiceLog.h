#import "MSAbstractLogInternal.h"
#import <Foundation/Foundation.h>

@interface MSStartServiceLog : MSAbstractLog

/**
 * Services which started with SDK
 */
@property(nonatomic) NSArray<NSString *> *services;

@end
