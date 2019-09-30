
  // Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAADAuthority.h"
#import "MSAbstractLogInternal.h"
#import "MSAuthConfig.h"
#import "MSB2CAuthority.h"
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

- (void)testConfigInitWithNoAuthoritiesTypeDictionary {

  // If
  NSDictionary *dic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/auth/path",
    @"authorities" : @[ @{@"default" : @YES, @"authority_url" : @"https://contoso.com/auth/path2"} ]
  };

  // When
  MSAuthConfig *config = [[MSAuthConfig alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqual(config.authorities.count, 0);
  XCTAssertFalse([config isValid]);
}

- (void)testConfigInitWithDictionary {

  // If
  NSDictionary *dic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/auth/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/auth/path1"}, @{
        @"type" : @"AAD",
        @"default" : @NO,
        @"audience" : @{@"type" : @"AzureADMyOrg", @"tenant_id" : @"00000000-0000-0000-0000-0000-00000000"}
      },
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
  }
  NSDictionary *b2cAuthority = dic[@"authorities"][0];
  XCTAssertEqualObjects([NSURL URLWithString:b2cAuthority[@"authority_url"]], config.authorities[0].authorityUrl);
  NSDictionary *aadAuthority = dic[@"authorities"][1];
  NSString *aadAuthorityTenantId = aadAuthority[@"audience"][@"tenant_id"];
  NSURL *aadAuthorityUrl = [NSURL URLWithString:[@"https://login.microsoftonline.com/" stringByAppendingString:aadAuthorityTenantId]];
  XCTAssertEqualObjects(aadAuthorityUrl, config.authorities[1].authorityUrl);
  NSDictionary *randomAuthority = dic[@"authorities"][2];
  XCTAssertEqualObjects([NSURL URLWithString:randomAuthority[@"authority_url"]], config.authorities[2].authorityUrl);
}

- (void)testInvalidConfig {

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

  // when
  MSAuthority *auth = [MSAuthority new];
  auth.type = @"randomType";
  auth.defaultAuthority = @YES;
  auth.authorityUrl = (NSURL * _Nonnull)[NSURL URLWithString:@"https://contoso.com/auth"];
  NSArray<MSAuthority *> *auths = [NSArray arrayWithObject:auth];
  config.authorities = auths;

  // then
  XCTAssertFalse([config isValid]);
}

- (void)testValidB2CConfig {

  // If
  MSAuthConfig *config = [MSAuthConfig new];
  config.authScope = @"scope";
  config.clientId = @"clientId";
  config.redirectUri = @"redirectUri";

  // When
  MSAuthority *b2cAuth = [MSB2CAuthority new];
  NSArray<MSAuthority *> *auths = [NSArray arrayWithObject:b2cAuth];
  config.authorities = auths;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  b2cAuth.type = @"B2C";
  b2cAuth.defaultAuthority = true;
  b2cAuth.authorityUrl = [NSURL URLWithString:@"https://contoso.com/auth/path"];

  // Then
  XCTAssertTrue([config isValid]);

  // When
  b2cAuth.type = @"notB2C";

  // Then
  XCTAssertFalse([config isValid]);
}

- (void)testValidAADConfig {

  // If
  MSAuthConfig *config = [MSAuthConfig new];
  config.authScope = @"scope";
  config.clientId = @"clientId";
  config.redirectUri = @"redirectUri";

  // When
  MSAuthority *aadAuth = [MSAADAuthority new];
  NSArray<MSAuthority *> *auths = [NSArray arrayWithObject:aadAuth];
  config.authorities = auths;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  aadAuth.type = @"AAD";
  aadAuth.defaultAuthority = true;
  aadAuth.authorityUrl = [NSURL URLWithString:@"https://contoso.com/auth/path"];

  // Then
  XCTAssertTrue([config isValid]);

  // When
  aadAuth.type = @"notAAD";
  XCTAssertFalse([config isValid]);
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
  MSAuthority *authB2C = [MSB2CAuthority new];
  authB2C.type = @"B2C";
  authB2C.defaultAuthority = YES;
  NSURL *URLB2C = [NSURL URLWithString:@"https://contoso.com/auth/path"];
  authB2C.authorityUrl = URLB2C;

  NSArray<MSAuthority *> *auths = [NSArray arrayWithObjects:auth1, authB2C, nil];
  config.authorities = auths;

  // Then
  XCTAssertTrue([config isValid]);
}

@end
d
