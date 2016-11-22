#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>

#import "MSWrapperExceptionManager.h"
#import "MSException.h"
#import "MSCrashes.h"

@interface MSWrapperExceptionManagerTests : NSObject<MSWrapperCrashesInitializationDelegate>, XCTestCase,

@end

@implementation MSWrapperExceptionManagerTests :

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

- (void)testWrapperExceptionNoDataDiskOperations {
  MSException *anEx = [self anException];
  [MSWrapperExceptionManager setWrapperException:anEx];
  [MSWrapperExceptionManager setWrapperExceptionData:[self someData]];

  CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

  [MSWrapperExceptionManager saveWrapperException:uuidRef];
  MSException *exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];

  assert([exception isEqual:anEx]);

  NSData* data = [MSWrapperExceptionManager loadWrapperExceptionDataWithUUIDString:[self uuidRefToString:uuidRef]];
  assert([data isEqualToData:[self someData]]);

  [MSWrapperExceptionManager deleteWrapperExceptionWithUUID:uuidRef];
  exception = [MSWrapperExceptionManager loadWrapperException:uuidRef];

  assert(exception == nil);

  CFRelease(uuidRef);
}

- (void)testStartingFromWrapperSdk {
  InitializationDelegate del = [[InitializationDelegate alloc] init];
  del.handlersWereSetUp = NO;
  [MSWrapperExceptionManager setDelegate:del];
  InitializationDelegate gottenDel = [MSWrapperExceptionManager getDelegate];
  assert(del == gottenDel);

  [[MSCrashes sharedInstance] applyEnabledState:YES];
  assert(del.handlersWereSetUp);
}


- (void) setUpCrashHandlers {
  handlersWereSetUp = YES;
  [MSWrapperExceptionManager startCrashReportingFromWrapperSdk];
}

@end
