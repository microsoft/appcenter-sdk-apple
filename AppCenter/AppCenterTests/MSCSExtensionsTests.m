#import "MSTestFrameworks.h"
#import "MSUserExtension.h"

@interface MSCSExtensionsTests : XCTestCase
@property(nonatomic) MSUserExtension *userExt;
@end

@implementation MSCSExtensionsTests

- (void)setUp {
    [super setUp];
  self.userExt = [MSUserExtension new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSerializingUserExtToDictionaryWorks {
  
  // If
  NSString *userLocale = @"EN-US";
  self.userExt.locale = userLocale;
  
  // When
  NSMutableDictionary *dict = [self.userExt serializeToDictionary];
  
  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqual(dict[], <#expression2, ...#>)
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
