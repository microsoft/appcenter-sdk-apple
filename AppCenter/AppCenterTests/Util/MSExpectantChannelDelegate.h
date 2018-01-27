
#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"
#import "MSLog.h"

typedef void (^LogPersistedHandler)(id<MSLog>, NSString*, BOOL);

@interface MSExpectantChannelDelegate : NSObject <MSChannelDelegate>

@property (nonatomic) LogPersistedHandler persistedHandler;

@end
