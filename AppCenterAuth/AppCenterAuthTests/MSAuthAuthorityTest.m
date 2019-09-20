// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAADAuthority.h"
#import "MSAbstractLogInternal.h"
#import "MSAuthority.h"
#import "MSB2CAuthority.h"
#import "MSTestFrameworks.h"

@interface MSAuthAuthorityTests : XCTestCase

@end

@implementation MSAuthAuthorityTests

#pragma mark - Tests

- (void)testAuthorityInitWithNilDictionary {

  // When
  MSAuthority *authority = [[MSAuthority alloc] initWithDictionary:(_Nonnull id)nil];

  // Then
  XCTAssertNil(authority);
}

- (void)testB2CAuthorityInitWithDictionary {

  // If
  NSMutableDictionary *dic = [@{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/auth/path"} mutableCopy];

  // When
  MSAuthority *authority = [[MSAuthority alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqualObjects(dic[@"type"], authority.type);
  XCTAssertEqual([dic[@"default"] boolValue], authority.defaultAuthority);
  XCTAssertEqualObjects([NSURL URLWithString:dic[@"authority_url"]], authority.authorityUrl);

  // If
  dic[@"default"] = @NO;

  // When
  authority = [[MSAuthority alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqual([dic[@"default"] boolValue], authority.defaultAuthority);
}

- (void)testB2CAuthorityIsValid {

  // If
  MSAuthority *auth = [MSB2CAuthority new];

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.type = @"B2C";

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.defaultAuthority = YES;

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  NSURL *URL = [NSURL URLWithString:@"https://contoso.com/auth/path"];
  auth.authorityUrl = URL;

  // Then
  XCTAssertTrue([auth isValid]);
}

- (void)testAADAuthorityInitWithDictionary {

  // If
  NSMutableDictionary *dic =
      [@{@"type" : @"AAD", @"default" : @YES, @"audience" : @{@"tenant_id" : @"tenantId", @"type" : @"AzureADMyOrg"}} mutableCopy];

  // When
  MSAuthority *authority = [[MSAADAuthority alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqualObjects(dic[@"type"], authority.type);
  XCTAssertEqual([dic[@"default"] boolValue], authority.defaultAuthority);
  XCTAssertEqualObjects([NSURL URLWithString:@"https://login.microsoftonline.com/tenantId"], authority.authorityUrl);

  // If
  dic[@"default"] = @NO;

  // When
  authority = [[MSAADAuthority alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqual([dic[@"default"] boolValue], authority.defaultAuthority);
}

- (void)testAADAuthorityIsValid {

  // If
  MSAuthority *auth = [MSAADAuthority new];

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.type = @"AAD";

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.defaultAuthority = YES;

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  NSURL *URL = [NSURL URLWithString:@"http://login.microsoftonline.com/tenantId"];
  auth.authorityUrl = URL;

  // Then
  XCTAssertTrue([auth isValid]);
}
@end
