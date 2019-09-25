// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSJwtClaims.h"
#import "MSAppCenterInternal.h"
#import "MSLogger.h"

static NSString *const kMSJwtPartsSeparator = @".";
static NSString *const kMSSubjectClaim = @"sub";
static NSString *const kMSExpirationClaim = @"exp";

@implementation MSJwtClaims

- (instancetype)initWithSubject:(NSString *)subject expiration:(NSDate *)expiration {
  self = [super init];
  if (self) {
    _subject = subject;
    _expiration = expiration;
  }
  return self;
}

+ (MSJwtClaims *)parse:(NSString *)jwt {
  if (jwt == nil) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT, token is nil.");
    return nil;
  }
  NSArray *parts = [jwt componentsSeparatedByString:kMSJwtPartsSeparator];
  if ([parts count] < 2) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT, not enough parts.");
    return nil;
  }
  NSString *base64ClaimsPart = parts[1];

  /*
   * NSData's base64 parser expects the length to be padded with '=' to indicate the size of the last "chunk."
   * Learn more here: https://tools.ietf.org/html/rfc4648#section-4.
   */
  int padding = 0;
  if ((base64ClaimsPart.length % 4) == 3) {
    padding = 1;
  } else if ((base64ClaimsPart.length % 4) == 2) {
    padding = 2;
  }
  unsigned long targetLength = base64ClaimsPart.length + padding;
  base64ClaimsPart = [base64ClaimsPart stringByPaddingToLength:targetLength withString:@"=" startingAtIndex:0];
  NSError *error;
  NSData *claimsPartData = [[NSData alloc] initWithBase64EncodedString:base64ClaimsPart options:0];
  NSDictionary *claims = [NSJSONSerialization JSONObjectWithData:claimsPartData options:0 error:&error];
  if (error != nil) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT: %@", error);
    return nil;
  }
  if ([claims objectForKey:kMSExpirationClaim] == nil || [claims objectForKey:kMSSubjectClaim] == nil) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT: seserialized claims missing `sub` or `exp`.");
    return nil;
  }
  NSObject *expirationTimeIntervalSince1970 = [claims objectForKey:kMSExpirationClaim];
  if (![expirationTimeIntervalSince1970 isKindOfClass:[NSNumber class]]) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT, `exp` claim in incorrect format.");
    return nil;
  }
  return [[MSJwtClaims alloc] initWithSubject:[claims objectForKey:kMSSubjectClaim]
                                   expiration:[[NSDate alloc] initWithTimeIntervalSince1970:[((NSNumber *)expirationTimeIntervalSince1970) longValue]]];
}

@end
