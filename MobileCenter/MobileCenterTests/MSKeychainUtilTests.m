#import "MSKeychainUtil.h"
#import <XCTest/XCTest.h>
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
  XCTAssertTrue([MSKeychainUtil storeString:value forKey:key andService:kServiceName]);
  assertThat([MSKeychainUtil stringForKey:key andService:kServiceName], equalTo(value));
  assertThat([MSKeychainUtil deleteStringForKey:key andService:kServiceName], equalTo(value));

  XCTAssertFalse([MSKeychainUtil stringForKey:key andService:kServiceName]);
  XCTAssertNil([MSKeychainUtil deleteStringForKey:key andService:kServiceName]);
}

@end
