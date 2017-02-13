#import <XCTest/XCTest.h>

#import "MSUpdatesInternal.h"

@interface MobileCenterUpdatesTests : XCTestCase

@property(nonatomic, strong) MSUpdates *sut;


@end

@implementation MobileCenterUpdatesTests

- (void)setUp {
  [super setUp];
  
  self.sut = [MSUpdates new];
}

- (void)testSetLoginUrlWorks {
  
  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setLoginUrl:testUrl];
  
  // Then
  XCTAssertTrue([[self.sut loginUrl] isEqualToString:testUrl]);
}

- (void)testSetUpdateUrlWorks {
  
  // When
  NSString *testUrl = @"https://example.com";
  [self.sut setUpdateUrl:testUrl];
  
  // Then
  XCTAssertTrue([[self.sut updateUrl] isEqualToString:testUrl]);
}

@end
