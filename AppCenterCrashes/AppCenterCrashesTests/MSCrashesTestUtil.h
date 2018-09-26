#import <Foundation/Foundation.h>

@class MSException;

@interface MSCrashesTestUtil : NSObject

+ (BOOL)createTempDirectory:(NSString *)directory;

+ (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename;

+ (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename;

+ (MSException *)exception;

@end
