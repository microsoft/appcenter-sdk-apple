#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import "MSNSAppDelegate.h"
#else
#import "MSUIAppDelegate.h"
#endif

@interface MSPushAppDelegate : NSObject <MSAppDelegate>

@end
