// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSAuthConfig.h"
#import "MSTestFrameworks.h"

@interface MSAuthConfigTests : XCTestCase

@end

@implementation MSAuthConfigTests

#pragma mark - Tests

- (void)testConfigInitWithNilDictionary {

  // When
  MSAuthConfig *config = [[MSAuthConfig alloc] initWithDictionary:(_Nonnull id)nil];

  // Then
  XCTAssertNil(config);
}

- (void)testConfigInitWithDictionary {

  // If
  NSDictionary *dic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/auth/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/auth/path1"},
      @{@"type" : @"RandomType", @"default" : @NO, @"authority_url" : @"https://contoso.com/auth/path2"}
    ]
  };

  // When
  MSAuthConfig *config = [[MSAuthConfig alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqualObjects(dic[@"identity_scope"], config.authScope);
  XCTAssertEqualObjects(dic[@"client_id"], config.clientId);
  XCTAssertEqualObjects(dic[@"redirect_uri"], config.redirectUri);
  for (NSUInteger i = 0; i < config.authorities.count; i++) {
    NSDictionary *authority = dic[@"authorities"][i];
    XCTAssertEqualObjects(authority[@"type"], config.authorities[i].type);
    XCTAssertEqual([authority[@"default"] boolValue], ((MSAuthority *)config.authorities[i]).defaultAuthority);
    XCTAssertEqualObjects([NSURL URLWithString:authority[@"authority_url"]], config.authorities[i].authorityUrl);
  }
}

- (void)testConfigIsValid {

  // If
  MSAuthConfig *config = [MSAuthConfig new];

  // Then
  XCTAssertFalse([config isValid]);

  // When
  config.authScope = @"scope";

  // Then
  XCTAssertFalse([config isValid]);

  // When
  config.clientId = @"clientId";

  // Then
  XCTAssertFalse([config isValid]);

  // When
  config.redirectUri = @"redirectUri";

  // Then
  XCTAssertFalse([config isValid]);

  // When
  MSAuthority *auth = [MSAuthority new];
  NSArray<MSAuthority *> *auths = [NSArray arrayWithObject:auth];
  config.authorities = auths;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  auth.type = @"B2C";
  auth.defaultAuthority = true;
  NSURL *URL = [NSURL URLWithString:@"https://contoso.com/auth/path"];
  auth.authorityUrl = URL;

  // Then
  XCTAssertTrue([config isValid]);
}

- (void)testMultipleAuthorities {

  // If
  MSAuthConfig *config = [MSAuthConfig new];
  config.authScope = @"scope";
  config.clientId = @"clientId";
  config.redirectUri = @"redirectUri";

  MSAuthority *auth1 = [MSAuthority new];
  auth1.type = @"RandomType";
  auth1.defaultAuthority = NO;
  NSURL *URL1 = [NSURL URLWithString:@"https://contoso.com/auth/path"];
  auth1.authorityUrl = URL1;

  NSArray<MSAuthority *> *auths1 = [NSArray arrayWithObject:auth1];
  config.authorities = auths1;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  MSAuthority *auth2 = [MSAuthority new];
  auth2.type = @"B2C";
  auth2.defaultAuthority = YES;
  NSURL *URL2 = [NSURL URLWithString:@"https://contoso.com/auth/path"];
  auth2.authorityUrl = URL2;

  NSArray<MSAuthority *> *auths2 = [NSArray arrayWithObjects:auth1, auth2, nil];
  config.authorities = auths2;

  // Then
  XCTAssertTrue([config isValid]);
}

@end
