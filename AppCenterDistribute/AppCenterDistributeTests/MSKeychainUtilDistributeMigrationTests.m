#import "MSDistributeInternal.h"
#import "MSKeychainUtil+DistributeMigration.h"
#import "MSKeychainUtilPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

@interface MSKeychainUtilDistributeMigrationTests : XCTestCase

@end

@implementation MSKeychainUtilDistributeMigrationTests

#pragma mark - Tests

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clear];
}

- (void)tearDown {
  [super tearDown];
  [MSKeychainUtil clear];
}

#if !TARGET_OS_TV
- (void)testDistributeDataMigration {
  
  // If
  NSString *mcToken = @"TokTok";
  NSString *mcServiceName = [NSString stringWithFormat:@"%@.%@", @"MobileCenter", [MS_APP_MAIN_BUNDLE bundleIdentifier]];
  XCTAssertTrue([MSKeychainUtil storeString:mcToken forKey:kMSUpdateTokenKey withServiceName:mcServiceName]);
  
  // When
  [MSKeychainUtil migrateDistributeData];
  
  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(mcToken));
  
  // If
  [MSKeychainUtil clear];
  
  // When
  [MSKeychainUtil migrateDistributeData];
  
  // Then
  assertThat([MSKeychainUtil stringForKey:kMSUpdateTokenKey], is(nilValue()));
}
#endif

@end
