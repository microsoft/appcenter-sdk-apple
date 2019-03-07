#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UserNotifications/UserNotifications.h>
#endif

#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitProtocol.h"
#import "MSTestFrameworks.h"
#import "MSUserIdContextPrivate.h"

@interface MSDataStoreTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDataStoreTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

@end
