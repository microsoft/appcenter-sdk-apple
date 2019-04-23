// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataUtils.h"
#import "MSUtility+Date.h"

@implementation MSDataUtils

+ (NSDate *)deserializeDate:(NSString *)dateString {
  return [MSUtility dateFromISO8601:dateString];
}

+ (NSString *)serializeDate:(NSDate *)date {
  return [MSUtility dateToISO8601:date];
}

@end
