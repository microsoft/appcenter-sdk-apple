#import <Foundation/Foundation.h>

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSIdentity.h"
#import "MSIdentityPrivate.h"
#import "MSMockUserDefaults.h"
#import "MSServiceAbstractProtected.h"
#import "MSTestFrameworks.h"
#import "MSUtility+File.h"

static NSString *const kMSTestAppSecret = @"TestAppSecret";

@interface MSIdentityTests : XCTestCase

@property(nonatomic) MSIdentity *sut;
@property(nonatomic) MSMockUserDefaults *settingsMock;
@property(nonatomic) NSDictionary *dummyConfigDic;
@property(nonatomic) id utilityMock;

@end

@implementation MSIdentityTests

- (void)setUp {
  [super setUp];
  self.settingsMock = [MSMockUserDefaults new];
  self.utilityMock = OCMClassMock([MSUtility class]);
  self.dummyConfigDic = @{
    @"identity_scope" : @"scope",
    @"client_id" : @"clientId",
    @"redirect_uri" : @"https://contoso.com/identity/path",
    @"authorities" : @[
      @{@"type" : @"B2C", @"default" : @YES, @"authority_url" : @"https://contoso.com/identity/path1"},
      @{@"type" : @"RandomType", @"default" : @NO, @"authority_url" : @"https://contoso.com/identity/path2"}
    ]
  };

  // When
  self.sut = [MSIdentity new];
}

- (void)tearDown {
  [super tearDown];
  [MSIdentity resetSharedInstance];
  [self.settingsMock stopMocking];
  [self.utilityMock stopMocking];
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

- (void)testCleanUpOnDisabling {

  // If
  MSIdentity *service = (MSIdentity *)[MSIdentity sharedInstance];
  NSData *serializedConfig = [NSJSONSerialization dataWithJSONObject:self.dummyConfigDic options:(NSJSONWritingOptions)0 error:nil];
  OCMStub([self.utilityMock loadDataForPathComponent:[service identityConfigFilePath]]).andReturn(serializedConfig);
  [self.settingsMock setObject:@"eTag" forKey:kMSIdentityETagKey];
  [[MSIdentity sharedInstance] startWithChannelGroup:OCMProtocolMock(@protocol(MSChannelGroupProtocol))
                                           appSecret:kMSTestAppSecret
                             transmissionTargetToken:nil
                                     fromApplication:YES];
  [service setEnabled:YES];

  // When
  [service setEnabled:NO];

  // Then
  XCTAssertNil(service.clientApplication);
  XCTAssertNil(service.accessToken);
  OCMVerify([self.utilityMock deleteItemForPathComponent:[service identityConfigFilePath]]);
  XCTAssertNil([self.settingsMock objectForKey:kMSIdentityETagKey]);
}
@end
