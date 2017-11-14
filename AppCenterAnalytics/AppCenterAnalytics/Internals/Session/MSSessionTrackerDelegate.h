#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"

@protocol MSSessionTrackerDelegate <NSObject>

@required

- (void)sessionTracker:(id)sessionTracker processLog:(id<MSLog>)log;

@end
