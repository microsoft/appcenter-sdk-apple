#import <XCTest/XCTest.h>
#import "MSBasicMachOParser.h"
#import "MSUtil.h"

@interface MSBasicMachOParserTests : XCTestCase
@end

@implementation MSBasicMachOParserTests


- (void)testReturnsNilIfBundleIsInvalid {
    //If
    NSBundle *nilBundle = nil;
    
    //When
    MSBasicMachOParser *parser = [[MSBasicMachOParser alloc] initWithBundle: nilBundle];
    
    //Then
    XCTAssertNil(parser);
    
    //If
    NSBundle *invalidBundle = [NSBundle alloc];
    
    //When
    parser = [[MSBasicMachOParser alloc] initWithBundle: invalidBundle];
    
    //Then
    XCTAssertNil(parser);
}

- (void)testReturnsParserForBundle {
    //If
    NSBundle *validBundle = [NSBundle bundleForClass:[MSBasicMachOParserTests class]];
    
    //When
    MSBasicMachOParser *parser = [[MSBasicMachOParser alloc] initWithBundle: validBundle];
    
    //Then
    XCTAssertNotNil(parser);
    XCTAssertNotNil(parser.uuid);
}

- (void)testReturnsParserForMainBundle{
    //When
    MSBasicMachOParser *parserForBundle = [[MSBasicMachOParser alloc] initWithBundle: MS_APP_MAIN_BUNDLE];
    MSBasicMachOParser *parserForMainBundle = [MSBasicMachOParser machOParserForMainBundle];
    
    //Then
    XCTAssertNotNil(parserForMainBundle);
    XCTAssertNotNil(parserForMainBundle.uuid);
    XCTAssertTrue([parserForBundle.uuid isEqual:parserForMainBundle.uuid]);
}

@end
