#import <Foundation/Foundation.h>

@interface MSCrashesUtil : NSObject

/**
 * Returns the directory for storing and reading crash reports for this app.
 *
 * @return The directory containing crash reports for this app.
 */
+ (NSURL *)crashesDir;

/**
 * Returns the directory for storing and reading buffered logs. It will be used in case we crash to make sure we don't
 * loose any data.
 *
 * @return The directory containing buffered events for an app
 */
+ (NSURL *)logBufferDir;

@end
