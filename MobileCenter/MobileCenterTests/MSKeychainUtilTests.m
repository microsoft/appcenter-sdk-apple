#import "MSKeychainUtil.h"
#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface MSKeychiainUtilTests : XCTestCase

@end

@implementation MSKeychiainUtilTests

static NSString *const kServiceName = @"Test Service";

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clearForService];
  [MSKeychainUtil clearForService:kServiceName];
}

- (void)tearDown {
  [super tearDown];
  [MSKeychainUtil clearForService];
  [MSKeychainUtil clearForService:kServiceName];
}

- (void)testKeychain {

  // If
  NSString *key = @"Test Key";
  NSString *value = @"Test Value";

  // Then
  XCTAssertTrue([MSKeychainUtil storeString:value forKey:key service:kServiceName]);
  assertThat([MSKeychainUtil stringForKey:key service:kServiceName], equalTo(value));
  assertThat([MSKeychainUtil deleteStringForKey:key service:kServiceName], equalTo(value));

  XCTAssertFalse([MSKeychainUtil stringForKey:key service:kServiceName]);
  XCTAssertNil([MSKeychainUtil deleteStringForKey:key service:kServiceName]);
}

- (void)testKeychainWithDefaultServiceName {

  // If
  NSString *key = @"Test Key";
  NSString *value = @"Test Value";

  // Then
  XCTAssertTrue([MSKeychainUtil storeString:value forKey:key]);
  assertThat([MSKeychainUtil stringForKey:key], equalTo(value));
  assertThat([MSKeychainUtil deleteStringForKey:key], equalTo(value));

  XCTAssertFalse([MSKeychainUtil stringForKey:key]);
  XCTAssertNil([MSKeychainUtil deleteStringForKey:key]);
}

@end
