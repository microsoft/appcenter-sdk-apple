
#import <Foundation/Foundation.h>

#import "MSChannelDelegate.h"
#import "MSLog.h"

typedef void (^logPersistedHandler)(id<MSLog>, NSString*, BOOL);

@interface MSExpectantChannelDelegate : NSObject <MSChannelDelegate>

@property (nonatomic) logPersistedHandler persistedHandler;

@end
