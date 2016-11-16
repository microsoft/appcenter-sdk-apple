#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "MSWrapperExceptionManager.h"
#import "MSException.h"

@interface MSWrapperExceptionManagerTests : XCTestCase

@end

@implementation MSWrapperExceptionManagerTests

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
- (void)testHasExceptionWorks {

  assert(![MSWrapperExceptionManager hasException]);
  [MSWrapperExceptionManager setWrapperExceptionData:[self someData]];
  assert(![MSWrapperExceptionManager hasException]);
  [MSWrapperExceptionManager setWrapperException:[self anException]];
  assert([MSWrapperExceptionManager hasException]);
}

- (void)testWrapperExceptionDiskOperations {
  [MSWrapperExceptionManager setWrapperException:[self anException]];

  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  [MSWrapperExceptionManager saveWrapperException:uuidRef];
  MSException *exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];

  assert([exception isEqual:[self anException]]);

  [MSWrapperExceptionManager deleteWrapperExceptionWithUUID:uuidRef];
  exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];

  assert(exception == nil);

  CFRelease(uuidRef);
}

- (void)testWrapperExceptionDataDiskOperations {
  [MSWrapperExceptionManager setWrapperExceptionData:[self someData]];
  [MSWrapperExceptionManager setWrapperException:[self anException]];

  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  [MSWrapperExceptionManager saveWrapperException:uuidRef];
  [MSWrapperExceptionManager saveWrapperExceptionData:uuidRef];


  NSString *uuidString = [self uuidRefToString:uuidRef];

  NSData* data =  [MSWrapperExceptionManager loadWrapperExceptionDataWithUUIDString:uuidString];
  assert([data isEqualToData:[self someData]]);

  [MSWrapperExceptionManager deleteWrapperExceptionDataWithUUIDString:uuidString];
  assert([data isEqualToData:[self someData]]);

  CFRelease(uuidRef);
}

@end
