#import "MSLoggerInternal.h"
#import "MSTestFrameworks.h"
#import "MSWrapperLogger.h"

@interface MSWrapperLoggerTests : XCTestCase

@end

@implementation MSWrapperLoggerTests

- (void)testWrapperLogger {

  // If
  __block XCTestExpectation *expectation = [self expectationWithDescription:@"Wrapper logger"];
  __block NSString *expectedMessage = @"expectedMessage";
  NSString *tag = @"TAG";
  __block NSString *message = nil;
  MSLogMessageProvider messageProvider = ^() {
    message = expectedMessage;
    [expectation fulfill];
    return message;
  };

  // When
  [MSLogger setCurrentLogLevel:MSLogLevelDebug];
  [MSWrapperLogger MSWrapperLog:messageProvider tag:tag level:MSLogLevelDebug];

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                                 XCTAssertEqual(expectedMessage, message);
                               }];
}

@end
