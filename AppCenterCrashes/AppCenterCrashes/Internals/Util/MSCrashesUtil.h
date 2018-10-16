#import <Foundation/Foundation.h>

static NSString *const kMSCrashesDirectory = @"crashes";
static NSString *const kMSLogBufferDirectory = @"crasheslogbuffer";
static NSString *const kMSWrapperExceptionsDirectory = @"crasheswrapperexceptions";

@interface MSCrashesUtil : NSObject

/**
 * Returns the directory for storing and reading crash reports for this app.
 *
 * @return The directory containing crash reports for this app.
 */
+ (NSString *)crashesDir;

/**
 * Returns the directory for storing and reading buffered logs. It will be used in case we crash to make sure we don't lose any data.
 *
 * @return The directory containing buffered events for an app
 */
+ (NSString *)logBufferDir;

/**
 * Returns the directory for storing and reading wrapper exception data.
 *
 * @return The directory containing wrapper exception data.
 */
+ (NSString *)wrapperExceptionsDir;

@end
