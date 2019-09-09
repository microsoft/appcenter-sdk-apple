// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSJwtClaims.h"
#import "MSTestFrameworks.h"

@interface MSJwtClaimsTests : XCTestCase
@end

@implementation MSJwtClaimsTests

static NSString *const kMSJwtFormat = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%@";

- (void)testGetValidJwt {
  NSString *userId = @"some_user_id";
  int expiration = 1426420800;
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%i\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];

  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  XCTAssertNotNil(claim);
  XCTAssertEqual([claim getSubject], userId);
  XCTAssertEqual([claim getExpirationDate], [[NSDate alloc] initWithTimeIntervalSince1970:expiration]);
}

- (void)testExpirationClaimMissing {
  NSString *userId = @"some_user_id";
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\"}", userId];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];

  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  XCTAssertNil(claim);
}

- (void)testSubjectClaimMissing {
  int expiration = 1426420800;
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"exp\":\"%i\"}", expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];

  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  XCTAssertNil(claim);
}

- (void)testExpirationClaimInvalid {
  NSString *userId = @"some_user_id";
  NSString *expiration = @"invalid expiration";
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%@\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];

  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  XCTAssertNil(claim);
}

- (void)testInvalidBase64Token {
  NSString *invalidJwt = @"invalidjwt";
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, invalidJwt];
  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  XCTAssertNil(claim);
}

- (void)testMissingParts {
  NSString *invalidJwt = @"invalidjwt";
  MSJwtClaims *claim = [MSJwtClaims parse:invalidJwt];

  XCTAssertNil(claim);
}

@end
