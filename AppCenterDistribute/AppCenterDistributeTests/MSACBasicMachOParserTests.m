// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACBasicMachOParser.h"
#import "MSACBasicMachOParserPrivate.h"
#import "MSACTestFrameworks.h"
#import "MSACUtility.h"

static NSUInteger const kMSACBytesToRead = 10;

@interface MSACBasicMachOParserTests : XCTestCase

@property(nonatomic, strong) id fileHandleMock;

@end

@implementation MSACBasicMachOParserTests

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
  MSACBasicMachOParser *parser = [[MSACBasicMachOParser alloc] initWithBundle:nilBundle];

  // Then
  XCTAssertNil(parser);

  // If
  NSBundle *invalidBundle = [NSBundle alloc];

  // When
  parser = [[MSACBasicMachOParser alloc] initWithBundle:invalidBundle];

  // Then
  XCTAssertNil(parser);
}

- (void)testReturnsParserForBundle {

  // If
  NSBundle *validBundle = [NSBundle bundleForClass:[MSACBasicMachOParserTests class]];

  // When
  MSACBasicMachOParser *parser = [[MSACBasicMachOParser alloc] initWithBundle:validBundle];

  // Then
  XCTAssertNotNil(parser);
  XCTAssertNotNil(parser.uuid);
}

- (void)testReturnsParserForMainBundle {

  // When
  MSACBasicMachOParser *parserForBundle = [[MSACBasicMachOParser alloc] initWithBundle:MSAC_APP_MAIN_BUNDLE];
  MSACBasicMachOParser *parserForMainBundle = [MSACBasicMachOParser machOParserForMainBundle];

  // Then
  XCTAssertNotNil(parserForMainBundle);
  XCTAssertNotNil(parserForMainBundle.uuid);
  XCTAssertTrue([parserForBundle.uuid isEqual:parserForMainBundle.uuid]);
}

- (void)testReadDataFromFileReturnsNOIfCannotRead {

  // If
  unsigned char buffer[kMSACBytesToRead];
  NSData *emptyData = [NSData data];
  OCMStub([self.fileHandleMock readDataOfLength:kMSACBytesToRead]).andReturn(emptyData);
  MSACBasicMachOParser *parser = [MSACBasicMachOParser machOParserForMainBundle];

  // When
  BOOL result = [parser readDataFromFile:self.fileHandleMock toBuffer:buffer ofLength:kMSACBytesToRead];

  // Then
  XCTAssertFalse(result);
}

- (void)testReadDataFromFileReturnsYesIfCanRead {

  // If
  unsigned char buffer[kMSACBytesToRead];
  NSData *dataWithContents = [NSData dataWithBytes:buffer length:kMSACBytesToRead];
  OCMStub([self.fileHandleMock readDataOfLength:kMSACBytesToRead]).andReturn(dataWithContents);
  MSACBasicMachOParser *parser = [MSACBasicMachOParser machOParserForMainBundle];

  // When
  BOOL result = [parser readDataFromFile:self.fileHandleMock toBuffer:buffer ofLength:kMSACBytesToRead];

  // Then
  XCTAssertTrue(result);
}

@end
