#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSNoAutoAssignSessionIdLog.h"

@interface MSStartServiceLog : MSAbstractLog <MSNoAutoAssignSessionIdLog>

/**
 * Services which started with SDK
 */
@property(nonatomic) NSArray<NSString *> *services;

@end
