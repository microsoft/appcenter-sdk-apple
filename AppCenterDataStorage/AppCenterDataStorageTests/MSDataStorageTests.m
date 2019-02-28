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

@interface MSDataStorageTests : XCTestCase

@property(nonatomic) id settingsMock;

@end

@implementation MSDataStorageTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

@end
