#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSWrapperExceptionManager.h"
#import "MSException.h"
#import "MSCrashes.h"

@interface MSWrapperExceptionManagerTests : XCTestCase
@end

@implementation MSWrapperExceptionManagerTests

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
  assertThatBool([MSWrapperExceptionManager hasException], isFalse());
  [MSWrapperExceptionManager setWrapperExceptionData:[self someData]];
  assertThatBool([MSWrapperExceptionManager hasException], isFalse());
  [MSWrapperExceptionManager setWrapperException:[self anException]];
  assertThatBool([MSWrapperExceptionManager hasException], isTrue());
}

- (void)testWrapperExceptionDiskOperations {
  [MSWrapperExceptionManager setWrapperException:[self anException]];

  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  [MSWrapperExceptionManager saveWrapperException:uuidRef];
  MSException *exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];
  assertThat(exception, equalTo([self anException]));

  [MSWrapperExceptionManager deleteWrapperExceptionWithUUID:uuidRef];
  exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];

  assertThat(exception, nilValue());

  CFRelease(uuidRef);
}

- (void)testWrapperExceptionDataDiskOperations {
  // Setup
  MSException *anEx = [self anException];
  [MSWrapperExceptionManager setWrapperException:anEx];
  [MSWrapperExceptionManager setWrapperExceptionData:[self someData]];
  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
  [MSWrapperExceptionManager saveWrapperException:uuidRef];

  // Test that data was saved and loaded properly
  NSData* data = [MSWrapperExceptionManager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  assertThat(data, equalTo([self someData]));

  // Even after deleting wrapper exception data, we should be able to read it from memory
  data = nil;
  [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  data = [MSWrapperExceptionManager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  assertThat(data, equalTo([self someData]));

  CFRelease(uuidRef);
}

-(void)testSaveAndLoadErrors {
  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  // Save/load when the wrapper exception has not been set
  [MSWrapperExceptionManager saveWrapperException:uuidRef];
  assertThatBool([MSWrapperExceptionManager hasException], isFalse());
  assertThat([MSWrapperExceptionManager loadWrapperException:uuidRef], nilValue());

  // Save/load when the wrapper exception has been set to nil
  [MSWrapperExceptionManager setWrapperException:nil];
  assertThatBool([MSWrapperExceptionManager hasException], isFalse());
  assertThat([MSWrapperExceptionManager loadWrapperException:uuidRef], nilValue());

  CFRelease(uuidRef);
}

@end
