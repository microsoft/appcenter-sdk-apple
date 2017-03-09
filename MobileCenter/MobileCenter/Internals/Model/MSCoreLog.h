#import <Foundation/Foundation.h>
#import "MSAbstractLog.h"

@interface MSCoreLog : MSAbstractLog

/**
 * Services which started with SDK
 */
@property (nonatomic) NSArray<NSString*> *services;

@end
