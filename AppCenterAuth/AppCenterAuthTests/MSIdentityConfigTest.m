// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSIdentityConfig.h"
#import "MSTestFrameworks.h"

@interface MSIdentityConfigTests : XCTestCase

@end

@implementation MSIdentityConfigTests

#pragma mark - Tests

- (void)testConfigInitWithNilDictionary {

  // When
  MSIdentityConfig *config = [[MSIdentityConfig alloc] initWithDictionary:(_Nonnull id)nil];

  // Then
  XCTAssertNil(config);
}

- (void)testConfigInitWithDictionary {

  // If
  NSDictionary *dic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/identity/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/identity/path1"},
      @{@"type" : @"RandomType", @"default" : @NO, @"authority_url" : @"https://contoso.com/identity/path2"}
    ]
  };

  // When
  MSIdentityConfig *config = [[MSIdentityConfig alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqualObjects(dic[@"identity_scope"], config.identityScope);
  XCTAssertEqualObjects(dic[@"client_id"], config.clientId);
  XCTAssertEqualObjects(dic[@"redirect_uri"], config.redirectUri);
  for (NSUInteger i = 0; i < config.authorities.count; i++) {
    NSDictionary *authority = dic[@"authorities"][i];
    XCTAssertEqualObjects(authority[@"type"], config.authorities[i].type);
    XCTAssertEqual([authority[@"default"] boolValue], ((MSIdentityAuthority *)config.authorities[i]).defaultAuthority);
    XCTAssertEqualObjects([NSURL URLWithString:authority[@"authority_url"]], config.authorities[i].authorityUrl);
  }
}

- (void)testConfigIsValid {

  // If
  MSIdentityConfig *config = [MSIdentityConfig new];

  // Then
  XCTAssertFalse([config isValid]);

  // When
  config.identityScope = @"scope";

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
  MSIdentityAuthority *auth = [MSIdentityAuthority new];
  NSArray<MSIdentityAuthority *> *auths = [NSArray arrayWithObject:auth];
  config.authorities = auths;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  auth.type = @"B2C";
  auth.defaultAuthority = true;
  NSURL *URL = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth.authorityUrl = URL;

  // Then
  XCTAssertTrue([config isValid]);
}

- (void)testMultipleAuthorities {

  // If
  MSIdentityConfig *config = [MSIdentityConfig new];
  config.identityScope = @"scope";
  config.clientId = @"clientId";
  config.redirectUri = @"redirectUri";

  MSIdentityAuthority *auth1 = [MSIdentityAuthority new];
  auth1.type = @"RandomType";
  auth1.defaultAuthority = NO;
  NSURL *URL1 = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth1.authorityUrl = URL1;

  NSArray<MSIdentityAuthority *> *auths1 = [NSArray arrayWithObject:auth1];
  config.authorities = auths1;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  MSIdentityAuthority *auth2 = [MSIdentityAuthority new];
  auth2.type = @"B2C";
  auth2.defaultAuthority = YES;
  NSURL *URL2 = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth2.authorityUrl = URL2;

  NSArray<MSIdentityAuthority *> *auths2 = [NSArray arrayWithObjects:auth1, auth2, nil];
  config.authorities = auths2;

  // Then
  XCTAssertTrue([config isValid]);
}

@end
