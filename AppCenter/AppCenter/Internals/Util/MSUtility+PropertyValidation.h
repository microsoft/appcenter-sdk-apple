#import <Foundation/Foundation.h>

#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityPropertyValidationCategory;

/**
 * Utility class that is used throughout the SDK.
 * Property validation part.
 */
@interface MSUtility (PropertyValidation)

+ (NSDictionary<NSString *, NSString *> *)validateProperties:(NSDictionary<NSString *, NSString *> *)properties
                                                  forLogName:(NSString *)logName
                                                        type:(NSString *)logType;

@end

NS_ASSUME_NONNULL_END
