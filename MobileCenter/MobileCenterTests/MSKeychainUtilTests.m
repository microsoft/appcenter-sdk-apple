#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>
#import "MSKeychainUtil.h"

@interface MSKeychiainUtilTests : XCTestCase

@end

@implementation MSKeychiainUtilTests

- (void)setUp {
  [super setUp];
  [MSKeychainUtil clear];
}

- (void)tearDown {
  [super tearDown];
  [MSKeychainUtil clear];
}

- (void)testKeychain {

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
