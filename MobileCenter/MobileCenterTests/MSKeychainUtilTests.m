#import "MSKeychainUtil.h"
@import XCTest;
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface MSKeychiainUtilTests : XCTestCase

@end

@implementation MSKeychiainUtilTests

static NSString *const kServiceName = @"Test Service";

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clearForService:kServiceName];
}

- (void)tearDown {
  [super tearDown];
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

@end
