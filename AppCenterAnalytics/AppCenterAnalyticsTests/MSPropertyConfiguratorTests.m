#import <XCTest/XCTest.h>

#import "MSPropertyConfiguratorPrivate.h"
#import "MSTestFrameworks.h"

@interface MSPropertyConfiguratorTests : XCTestCase

@property(nonatomic) MSPropertyConfigurator *sut;

@end

@implementation MSPropertyConfiguratorTests

- (void)setUp {
  [super setUp];
  
  self.sut = [MSPropertyConfigurator new];
}

- (void)tearDown {
  [super tearDown];
  self.sut = nil;
}

- (void)testInitializationWorks {
  
  // If
  
  // When
  
  // Then
  XCTAssertNotNil(self.sut);
  XCTAssertFalse(self.sut.shouldCollectDeviceId);
}

- (void)testCollectDeviceIdWorks {
  
  // When
  [self.sut collectDeviceId];
  
  // Then
  XCTAssertTrue(self.sut.shouldCollectDeviceId);
}

@end
