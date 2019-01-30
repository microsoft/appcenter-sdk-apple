#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSIdentity.h"
#import "MSIdentityPrivate.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSIdentityTests : XCTestCase

@property(nonatomic) MSIdentity *sut;
@property(nonatomic) id settingsMock;

@end

@implementation MSIdentityTests

- (void)setUp {
  [super setUp];
  self.sut = [MSIdentity new];
}

- (void)tearDown {
  [super tearDown];
  [MSIdentity resetSharedInstance];
}

- (void)testApplyEnabledStateWorks {

  // If
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                           appSecret:kMSTestAppSecret
                             transmissionTargetToken:nil
                                     fromApplication:YES];
  MSServiceAbstract *service = (MSServiceAbstract *)[MSIdentity sharedInstance];

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertFalse([service isEnabled]);

  // When
  [service setEnabled:YES];

  // Then
  XCTAssertTrue([service isEnabled]);
}

@end
