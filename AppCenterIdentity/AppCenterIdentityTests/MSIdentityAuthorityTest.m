#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSIdentityAuthority.h"
#import "MSTestFrameworks.h"

@interface MSIdentityAuthorityTests : XCTestCase

@end

@implementation MSIdentityAuthorityTests

#pragma mark - Tests

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
