#import <XCTest/XCTest.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>

@interface AvalancheHubTests : XCTestCase

@end

@implementation AvalancheHubTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
  
}

- (void)testOCMock {
  NSString *aString = OCMClassMock([NSString class]);
  OCMStub([aString lowercaseString]).andReturn(@"LOWER HELLO");
  XCTAssertEqual(@"LOWER HELLO", [aString lowercaseString]);
}

- (void)testOCHamcrest {
  NSString* aString = @"Test String";
  NSString* bString = @"Test String";
  assertThat(aString, equalTo(bString));
}

- (void)testOHHTTPStubs {
  [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return [request.URL.host isEqualToString:@"mywebservice.com"];
  } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
    NSString* fixture = OHPathForFile(@"wsresponse.json", self.class);
    return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                            statusCode:200 headers:@{@"Content-Type":@"application/json"}];
  }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
