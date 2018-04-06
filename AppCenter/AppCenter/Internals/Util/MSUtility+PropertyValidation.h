#import <Foundation/Foundation.h>

#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class that is used throughout the SDK.
 * Property validation part.
 */
@interface MSUtility (PropertyValidation)

+ (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                        type:(NSString *)logType
                                           withConsoleLogTag:(NSString *)consoleLogTag;

@end

NS_ASSUME_NONNULL_END
