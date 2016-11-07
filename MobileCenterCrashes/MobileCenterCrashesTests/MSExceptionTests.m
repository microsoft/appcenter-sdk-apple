#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "MSException.h"
#import "MSStackFrame.h"

@interface MSExceptionsTests : XCTestCase

@end

@implementation MSExceptionsTests

#pragma mark - Tests

- (void)testSerializingBinaryToDictionaryWorks {
  
  // If
  MSException *sut = [self exception];
  
  // When
  NSMutableDictionary *actual = [sut serializeToDictionary];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual[@"type"], equalTo(sut.type));
  assertThat(actual[@"message"], equalTo(sut.message));
  assertThat(actual[@"wrapper_sdk_name"], equalTo(sut.wrapperSdkName));
}

- (void)testNSCodingSerializationAndDeserializationWorks {
  
  // If
  MSException *sut = [self exception];
  
  // When
  NSData *serializedEvent =
  [NSKeyedArchiver archivedDataWithRootObject:sut];
  id actual = [NSKeyedUnarchiver unarchiveObjectWithData:serializedEvent];
  
  // Then
  assertThat(actual, notNilValue());
  assertThat(actual, instanceOf([MSException class]));
  
  MSException *actualException = actual;
  assertThat(actualException.type, equalTo(sut.type));
  assertThat(actualException.message, equalTo(sut.message));
  assertThat(actualException.wrapperSdkName, equalTo(sut.wrapperSdkName));
  assertThatInteger(actualException.frames.count, equalToInteger(1));
  assertThat(actualException.frames.firstObject.address, equalTo(@"frameAddress"));
  assertThat(actualException.frames.firstObject.code, equalTo(@"frameSymbol"));
}

#pragma mark - Helper

- (MSException *)exception {
  NSString *type = @"exception_type";
  NSString *message = @"message";
  NSString *wrapperSdkName = @"mobilecenter.xamarin";
  MSStackFrame *frame = [MSStackFrame new];
  frame.address = @"frameAddress";
  frame.code = @"frameSymbol";
  NSArray<MSStackFrame *>* frames = [NSArray arrayWithObject:frame];
  
  MSException *exception = [MSException new];
  exception.type = type;
  exception.message = message;
  exception.wrapperSdkName = wrapperSdkName;
  exception.frames = frames;
  
  return exception;
}

@end
