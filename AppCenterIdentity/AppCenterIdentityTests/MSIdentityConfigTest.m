#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSIdentityConfig.h"
#import "MSTestFrameworks.h"

@interface MSIdentityConfigTests : XCTestCase

@end

@implementation MSIdentityConfigTests

#pragma mark - Tests

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
  auth1.defaultAuthority = false;
  NSURL *URL1 = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth1.authorityUrl = URL1;

  NSArray<MSIdentityAuthority *> *auths1 = [NSArray arrayWithObject:auth1];
  config.authorities = auths1;

  // Then
  XCTAssertFalse([config isValid]);

  // When
  MSIdentityAuthority *auth2 = [MSIdentityAuthority new];
  auth2.type = @"B2C";
  auth2.defaultAuthority = true;
  NSURL *URL2 = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth2.authorityUrl = URL2;

  NSArray<MSIdentityAuthority *> *auths2 = [NSArray arrayWithObjects:auth1, auth2, nil];
  config.authorities = auths2;

  // Then
  XCTAssertTrue([config isValid]);
}

@end
