#import "MSDistributeDataMigration.h"
#import "MSDistributeInternal.h"
#import "MSKeychainUtilPrivate.h"
#import "MSMockKeychainUtil.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

@interface MSKeychainUtilDistributeMigrationTests : XCTestCase
@property(nonatomic) id keychainUtilMock;
@end

@implementation MSKeychainUtilDistributeMigrationTests

#pragma mark - Tests

- (void)setUp {
  [super setUp];
  self.keychainUtilMock = [MSMockKeychainUtil new];
}

- (void)tearDown {
  [super tearDown];
  [self.keychainUtilMock stopMocking];
}

#if !TARGET_OS_TV
- (void)testDistributeDataMigration {

  // No Token.

  // If
  NSString *mcToken = @"TokTok";
  NSString *mcServiceName = [NSString stringWithFormat:@"%@.%@", [MS_APP_MAIN_BUNDLE bundleIdentifier], @"MobileCenter"];

  // When
  [MSDistributeDataMigration migrateKeychain];

  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(nilValue()));
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName], is(nilValue()));

  // Just the Mobile Center token.

  // If
  XCTAssertTrue([MSKeychainUtil storeString:mcToken forKey:kMSUpdateTokenKey withServiceName:mcServiceName]);

  // When
  [MSDistributeDataMigration migrateKeychain];

  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(mcToken));
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName], is(nilValue()));

  // Just the App Center token.

  // If
  NSString *acToken = @"TokTokAC";
  [MSKeychainUtil clear];
  XCTAssertTrue([MSKeychainUtil storeString:acToken forKey:kMSUpdateTokenKey]);

  // When
  [MSDistributeDataMigration migrateKeychain];

  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(acToken));
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName], is(nilValue()));

  // Both App Center and Mobile Center tokens.

  // If
  XCTAssertTrue([MSKeychainUtil storeString:mcToken forKey:kMSUpdateTokenKey withServiceName:mcServiceName]);

  // When
  [MSDistributeDataMigration migrateKeychain];

  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(acToken));
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey withServiceName:mcServiceName], is(nilValue()));
}
#endif

@end
