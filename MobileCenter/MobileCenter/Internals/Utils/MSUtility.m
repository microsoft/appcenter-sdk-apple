#import "MSUtility+Application.h"
#import "MSUtility+Environment.h"
#import "MSUtility+Date.h"
#import "MSUtility+StringFormatting.h"

@implementation MSUtility

/**
 * @discussion
 * Workaround for exporting symbols from category object files. 
 * See article https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96#.aedfl1kl0
 */
__attribute__((used)) static void importCategories () {
    [NSString stringWithFormat:@"%@ %@ %@ %@", MSUtilityApplicationCategory, MSUtilityEnvironmentCategory,
     MSUtilityDateCategory, MSUtilityStringFormattingCategory];
}

@end
