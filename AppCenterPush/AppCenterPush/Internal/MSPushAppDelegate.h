#import <Foundation/Foundation.h>

#import "MSAppDelegateForwarder.h"
#import "MSCustomPushApplicationDelegate.h"

@interface MSPushAppDelegate : NSObject <MSCustomPushApplicationDelegate>

@end

#pragma mark - Forwarding

@interface MSAppDelegateForwarder (MSPush) <MSCustomPushApplicationDelegate>

@end
