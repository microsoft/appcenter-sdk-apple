#import "MSUtility+Date.h"

/*
 * Workaround for exporting symbols from category object files.
 */
NSString *MSUtilityDateCategory;

@implementation MSUtility (Date)

+ (NSTimeInterval)nowInMilliseconds {
  return ([[NSDate date] timeIntervalSince1970] * 1000);
}

+ (NSString *)dateToISO8601:(NSDate *)date {
  static NSDateFormatter *dateFormatter = nil;
  if (!dateFormatter) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale systemLocale]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  }
  return [dateFormatter stringFromDate:date];
}

@end
