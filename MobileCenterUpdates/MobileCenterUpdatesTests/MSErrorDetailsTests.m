#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSErrorDetails.h"

@interface MSErrorDetailsTests : XCTestCase

@end

@implementation MSErrorDetailsTests

#pragma mark - Tests

- (void)testInitializeWithDictionary {
  NSString *filename = [[NSBundle bundleForClass:[self class]] pathForResource:@"error_details" ofType:@"json"];
  MSErrorDetails *details = [[MSErrorDetails alloc]
      initWithDictionary:[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filename]
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil]];

  assertThat(details.code, equalTo(@"no_releases_for_app"));
  assertThat(details.message, equalTo(@"Couldn't get a release because there are no releases for this app."));
}

@end
