// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSJwtClaims.h"
#import "MSTestFrameworks.h"

@interface MSJwtClaimsTests : XCTestCase

@end

@implementation MSJwtClaimsTests

static NSString *const kMSJwtFormat = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%@.blah";

- (void)testGetValidJwt {

  // If
  // The expiration doesn't matter, we just want to verify that what we put in is what we get out.
  int expiration = 1000;
  NSString *userId = @"some_user_id";
  NSDate *expirationAsDate = [[NSDate alloc] initWithTimeIntervalSince1970:expiration];
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%i\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  // When
  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  // Then
  XCTAssertNotNil(claim);
  XCTAssertEqualObjects(claim.subject, userId);
  XCTAssertEqualObjects(claim.expiration, expirationAsDate);
}

- (void)testNilJwt {
  
  // When
  MSJwtClaims *claims = [MSJwtClaims parse:nil];
  
  // Then
  XCTAssertNil(claims);
}

- (void)testExpirationClaimMissing {

  // If
  NSString *userId = @"some_user_id";
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\"}", userId];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  // When
  MSJwtClaims *claims = [MSJwtClaims parse:combinedJwt];

  // Then
  XCTAssertNil(claims);
}

- (void)testSubjectClaimMissing {

  // If
  int expiration = 0;
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"exp\":\"%i\"}", expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  // When
  MSJwtClaims *claim = [MSJwtClaims parse:combinedJwt];

  // Then
  XCTAssertNil(claim);
}

- (void)testExpirationClaimInvalid {

  // If
  NSString *userId = @"some_user_id";
  NSString *expiration = @"invalid expiration";
  NSString *jsonClaims = [NSString stringWithFormat:@"{\"sub\":\"%@\",\"exp\":\"%@\"}", userId, expiration];
  NSData *nsdata = [jsonClaims dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, base64Encoded];

  // When
  MSJwtClaims *claims = [MSJwtClaims parse:combinedJwt];

  // Then
  XCTAssertNotNil(claims);
  XCTAssertEqualObjects(claims.subject, userId);
  XCTAssertEqualObjects(claims.expiration, [[NSDate alloc] initWithTimeIntervalSince1970:0]);
}

- (void)testInvalidBase64Token {

  // If
  NSString *invalidTokenPart = @"invalidTokenPart";
  NSString *combinedJwt = [NSString stringWithFormat:kMSJwtFormat, invalidTokenPart];

  // When
  MSJwtClaims *claims = [MSJwtClaims parse:combinedJwt];

  // Then
  XCTAssertNil(claims);
}

- (void)testMissingParts {

  // If
  NSString *invalidJwt = @"invalidjwt";

  // When
  MSJwtClaims *claims = [MSJwtClaims parse:invalidJwt];

  // Then
  XCTAssertNil(claims);
}

@end
