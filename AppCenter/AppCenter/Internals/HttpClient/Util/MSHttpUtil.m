// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpUtil.h"

@implementation MSHttpUtil

+ (BOOL)isRecoverableError:(NSInteger)statusCode {

  // There are some cases when statusCode is 0, e.g., when server is unreachable. If so, the error will contain more details.
  return statusCode >= 500 || statusCode == 408 || statusCode == 429 || statusCode == 0;
}

+ (NSString *)hideSecret:(NSString *)secret {

  // Hide everything if secret is shorter than the max number of displayed characters.
  NSUInteger appSecretHiddenPartLength =
  (secret.length > kMSMaxCharactersDisplayedForAppSecret ? secret.length - kMSMaxCharactersDisplayedForAppSecret : secret.length);
  NSString *appSecretHiddenPart = [@"" stringByPaddingToLength:appSecretHiddenPartLength
                                                    withString:kMSHidingStringForAppSecret
                                               startingAtIndex:0];
  return [secret stringByReplacingCharactersInRange:NSMakeRange(0, appSecretHiddenPart.length) withString:appSecretHiddenPart];
}

+ (NSString *)hideAuthToken:(NSString *)token {

  // Hide token value.
  NSString *prefix = [[token componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];
  return [prefix stringByAppendingString:@" ***"];
}

@end
