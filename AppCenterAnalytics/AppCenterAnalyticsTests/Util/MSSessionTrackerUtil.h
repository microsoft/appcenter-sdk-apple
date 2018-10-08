#import <Foundation/Foundation.h>

@interface MSSessionTrackerUtil : NSObject

+ (void)simulateDidEnterBackgroundNotification;

+ (void)simulateWillEnterForegroundNotification;

@end
