#import "MobileCenter+Internal.h"
#import <Foundation/Foundation.h>

@protocol MSSessionTrackerDelegate <NSObject>

@required

- (void)sessionTracker:(id)sessionTracker processLog:(id<MSLog>)log withPriority:(MSPriority)priority;

@end
