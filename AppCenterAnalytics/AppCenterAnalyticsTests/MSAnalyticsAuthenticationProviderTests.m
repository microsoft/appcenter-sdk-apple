#import <XCTest/XCTest.h>

#import "MSAnalyticsAuthenticationProviderInternal.h"
#import "MSTestFrameworks.h"
#import "MSUtility+StringFormatting.h"

@interface MSAnalyticsAuthenticationProviderTests : XCTestCase

@property(nonatomic) MSAnalyticsAuthenticationProvider *sut;

@end

@implementation MSAnalyticsAuthenticationProviderTests

- (void)setUp {
  [super setUp];

  self.sut = [[MSAnalyticsAuthenticationProvider alloc]
      initWithAuthenticationType:MSAnalyticsAuthenticationTypeMSA
                       ticketKey:@"ticketKey1"
               completionHandler:^NSString *_Nullable {
                 return @"authenticationTicket";
               }];
}

- (void)tearDown {
  [super tearDown];

  self.sut = nil;
}

- (void)testInitialization {

  // Then
  XCTAssertNotNil(self.sut);
  XCTAssertEqual(self.sut.type, MSAnalyticsAuthenticationTypeMSA);
  XCTAssertNotNil(self.sut.ticketKey);
  XCTAssertNotNil(self.sut.ticketKeyHash);
  XCTAssertTrue([self.sut.ticketKeyHash
                 isEqualToString:[MSUtility sha256:@"ticketKey1"]]);
  XCTAssertNotNil(self.sut.completionHandler);
  NSString *returnValue = self.sut.completionHandler();
  XCTAssertTrue([returnValue isEqualToString:@"authenticationTicket"]);
}

@end
