#import <Foundation/Foundation.h>
#import "MSAbstractLog.h"

@interface MSStartServiceLog : MSAbstractLog

/**
 * Services which started with SDK
 */
@property (nonatomic) NSArray<NSString*> *services;

@end
