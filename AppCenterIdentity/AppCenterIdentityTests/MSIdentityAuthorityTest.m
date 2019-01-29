#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSIdentityAuthority.h"
#import "MSTestFrameworks.h"

@interface MSIdentityAuthorityTests : XCTestCase

@end

@implementation MSIdentityAuthorityTests

#pragma mark - Tests

- (void)testAuthorityInitWithNilDictionary {

  // When
  MSIdentityAuthority *authority = [[MSIdentityAuthority alloc] initWithDictionary:(_Nonnull id)nil];

  // Then
  XCTAssertNil(authority);
}

- (void)testAuthorityInitWithDictionary {

  // If
  NSDictionary *dic = @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/identity/path"};

  // When
  MSIdentityAuthority *authority = [[MSIdentityAuthority alloc] initWithDictionary:dic];

  // Then
  XCTAssertEqualObjects(dic[@"type"], authority.type);
  XCTAssertEqual([dic[@"default"] boolValue], authority.defaultAuthority);
  XCTAssertEqualObjects([NSURL URLWithString:dic[@"authority_url"]], authority.authorityUrl);
}

- (void)testAuthorityIsValid {

  // If
  MSIdentityAuthority *auth = [MSIdentityAuthority new];

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.type = @"B2C";

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  auth.defaultAuthority = true;

  // Then
  XCTAssertFalse([auth isValid]);

  // When
  NSURL *URL = [NSURL URLWithString:@"https://contoso.com/identity/path"];
  auth.authorityUrl = URL;

  // Then
  XCTAssertTrue([auth isValid]);
}

@end
