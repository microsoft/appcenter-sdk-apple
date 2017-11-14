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
  return [[MSUtility ISO8601DateFormatter] stringFromDate:date];
}

+ (NSDate *)dateFromISO8601:(NSString *)string {
  return [[MSUtility ISO8601DateFormatter] dateFromString:string];
}

+ (NSDateFormatter *)ISO8601DateFormatter {
  static NSDateFormatter *dateFormatter = nil;
  if (!dateFormatter) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale systemLocale]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
  }
  return dateFormatter;
}

@end
