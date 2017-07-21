#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>
#import "MSCrashes.h"
#import "MSException.h"
#import "MSWrapperException.h"
#import "MSWrapperExceptionManagerInternal.h"

@interface MSWrapperExceptionManagerTests : XCTestCase<MSWrapperCrashesInitializationDelegate>
@end

@implementation MSWrapperExceptionManagerTests

#pragma mark - Housekeeping

//- (void)setUp {
//  [super setUp];
//}
//
//- (void)tearDown {
//  [super tearDown];
//}

#pragma mark - Helper

- (MSException*) getModelException {
  MSException *exception = [[MSException alloc] init];
  exception.message = @"a message";
  exception.type = @"a type";
  return exception;
}

- (NSData*) getData {
  NSString *string = @"some string";
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  return data;
}

- (MSWrapperException*) getWrapperException {
  MSWrapperException *wrapperException = [[MSWrapperException alloc] init];
  wrapperException.modelException = [self getModelException];
  wrapperException.exceptionData = [self getData];
  wrapperException.processId = [NSNumber numberWithInt:4];
  return wrapperException;
}

- (NSString*)uuidRefToString:(CFUUIDRef)uuidRef {
  if (!uuidRef) {
    return nil;
  }
  CFStringRef uuidStringRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
  return (__bridge_transfer NSString*)uuidStringRef;
}

#pragma mark - Test

- (void) testSaveCorrelateAndLoadWrapperExceptionWorks {
  MSWrapperException * wrapperException = [self getWrapperException];
  [MSWrapperExceptionManager saveWrapperException:wrapperException];

  //create some crash reports and then correlate then load then compare


}


@end
