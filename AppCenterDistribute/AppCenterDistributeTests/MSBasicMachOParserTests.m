#import "MSBasicMachOParser.h"
#import "MSBasicMachOParserPrivate.h"
#import "MSTestFrameworks.h"
#import "MSUtility.h"

static NSUInteger const kMSBytesToRead = 10;

@interface MSBasicMachOParserTests : XCTestCase

@property(nonatomic, strong) id fileHandleMock;

@end

@implementation MSBasicMachOParserTests

- (void)setUp {
  [super setUp];
  self.fileHandleMock = OCMClassMock([NSFileHandle class]);
}

- (void)tearDown {
  [super tearDown];
  [self.fileHandleMock stopMocking];
}

- (void)testReturnsNilIfBundleIsInvalid {

  // If
  NSBundle *nilBundle = nil;

  // When
  MSBasicMachOParser *parser = [[MSBasicMachOParser alloc] initWithBundle:nilBundle];

  // Then
  XCTAssertNil(parser);

  // If
  NSBundle *invalidBundle = [NSBundle alloc];

  // When
  parser = [[MSBasicMachOParser alloc] initWithBundle:invalidBundle];

  // Then
  XCTAssertNil(parser);
}

- (void)testReturnsParserForBundle {

  // If
  NSBundle *validBundle = [NSBundle bundleForClass:[MSBasicMachOParserTests class]];

  // When
  MSBasicMachOParser *parser = [[MSBasicMachOParser alloc] initWithBundle:validBundle];

  // Then
  XCTAssertNotNil(parser);
  XCTAssertNotNil(parser.uuid);
}

- (void)testReturnsParserForMainBundle {

  // When
  MSBasicMachOParser *parserForBundle = [[MSBasicMachOParser alloc] initWithBundle:MS_APP_MAIN_BUNDLE];
  MSBasicMachOParser *parserForMainBundle = [MSBasicMachOParser machOParserForMainBundle];

  // Then
  XCTAssertNotNil(parserForMainBundle);
  XCTAssertNotNil(parserForMainBundle.uuid);
  XCTAssertTrue([parserForBundle.uuid isEqual:parserForMainBundle.uuid]);
}

- (void)testReadDataFromFileReturnsNOIfCannotRead {

  // If
  unsigned char buffer[kMSBytesToRead];
  NSData *emptyData = [NSData data];
  OCMStub([self.fileHandleMock readDataOfLength:kMSBytesToRead]).andReturn(emptyData);
  MSBasicMachOParser *parser = [MSBasicMachOParser machOParserForMainBundle];

  // When
  BOOL result = [parser readDataFromFile:self.fileHandleMock toBuffer:buffer ofLength:kMSBytesToRead];

  // Then
  XCTAssertFalse(result);
}

- (void)testReadDataFromFileReturnsYesIfCanRead {

  // If
  unsigned char buffer[kMSBytesToRead];
  NSData *dataWithContents = [NSData dataWithBytes:buffer length:kMSBytesToRead];
  OCMStub([self.fileHandleMock readDataOfLength:kMSBytesToRead]).andReturn(dataWithContents);
  MSBasicMachOParser *parser = [MSBasicMachOParser machOParserForMainBundle];

  // When
  BOOL result = [parser readDataFromFile:self.fileHandleMock toBuffer:buffer ofLength:kMSBytesToRead];

  // Then
  XCTAssertTrue(result);
}

@end
