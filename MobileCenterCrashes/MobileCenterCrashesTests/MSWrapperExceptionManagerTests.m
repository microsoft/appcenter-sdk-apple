#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSWrapperExceptionManagerInternal.h"
#import "MSException.h"
#import "MSCrashes.h"

@interface MSWrapperExceptionManagerTests : XCTestCase

@property(nonatomic, strong) MSWrapperExceptionManager *manager;

@end


@implementation MSWrapperExceptionManagerTests

#pragma mark - Housekeeping

- (void)setUp {
  [super setUp];
  self.manager = [MSWrapperExceptionManager new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Helper

- (MSException*)anException {
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData*)someData {
  NSString *string = @"some string";
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  return data;
}

- (NSString*)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString*)uuidStringRef;
}

#pragma mark - Test

- (void)testHasExceptionWorks {
  assertThatBool([self.manager hasException], isFalse());
  self.manager.unsavedWrapperExceptionData = [self someData];
  assertThatBool([self.manager hasException], isFalse());
  self.manager.wrapperException = [self anException];
  assertThatBool([self.manager hasException], isTrue());
}

- (void)testWrapperExceptionDiskOperations {
  self.manager.wrapperException = [self anException];

  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  [self.manager saveWrapperException:uuidRef];
  MSException *exception = [self.manager loadWrapperException:uuidRef];
  assertThat(exception, equalTo([self anException]));

  [self.manager deleteWrapperExceptionWithUUID:uuidRef];
  exception = [self.manager loadWrapperException:uuidRef];

  assertThat(exception, nilValue());

  CFRelease(uuidRef);
}

- (void)testWrapperExceptionDataDiskOperations {
  // Setup
  self.manager.wrapperException = [self anException];
  self.manager.unsavedWrapperExceptionData = [self someData];
  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
  [self.manager saveWrapperException:uuidRef];

  // Test that data was saved and loaded properly
  NSData* data = [self.manager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  assertThat(data, equalTo([self someData]));

  // Even after deleting wrapper exception data, we should be able to read it from memory
  data = nil;
  [self.manager deleteWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  data = [self.manager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  assertThat(data, equalTo([self someData]));

  CFRelease(uuidRef);
}

-(void)testSaveAndLoadErrors {
  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  // Load data when wrapper data has not been set
  NSData* data = [self.manager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];

  // Save/load when the wrapper exception has not been set
  [self.manager saveWrapperException:uuidRef];
  assertThatBool([self.manager hasException], isFalse());
  assertThat([self.manager loadWrapperException:uuidRef], nilValue());

  // Load when the wrapper exception has been set to nil
  self.manager.wrapperException = nil;
  assertThatBool([self.manager hasException], isFalse());
  assertThat([self.manager loadWrapperException:uuidRef], nilValue());

  CFRelease(uuidRef);
}

@end
