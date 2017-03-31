#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <XCTest/XCTest.h>

#import "MSCustomProperties.h"
#import "MSCustomPropertiesPrivate.h"

@interface MSCustomPropertiesTests : XCTestCase

@end

@implementation MSCustomPropertiesTests

- (void)testKeyValidate {
  
  // If
  NSString *string = @"test";
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
  NSNumber *number = @0;
  BOOL boolean = NO;
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Null key.
  // When
  NSString *nullKey = nil;
  [customProperties setString:string forKey:nullKey];
  [customProperties setDate:date forKey:nullKey];
  [customProperties setNumber:number forKey:nullKey];
  [customProperties setBool:boolean forKey:nullKey];
  [customProperties clearPropertyForKey:nullKey];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Invalid key.
  // When
  NSString *invalidKey = @"!";
  [customProperties setString:string forKey:invalidKey];
  [customProperties setDate:date forKey:invalidKey];
  [customProperties setNumber:number forKey:invalidKey];
  [customProperties setBool:boolean forKey:invalidKey];
  [customProperties clearPropertyForKey:invalidKey];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Normal keys.
  // When
  [customProperties setString:string forKey:@"t1"];
  [customProperties setDate:date forKey:@"t2"];
  [customProperties setNumber:number forKey:@"t3"];
  [customProperties setBool:boolean forKey:@"t4"];
  [customProperties clearPropertyForKey:@"t5"];
  
  // Then
  assertThat([customProperties properties], hasCountOf(5));
  
  // Already contains keys.
  // When
  [customProperties setString:string forKey:@"t1"];
  [customProperties setDate:date forKey:@"t2"];
  [customProperties setNumber:number forKey:@"t3"];
  [customProperties setBool:boolean forKey:@"t4"];
  [customProperties clearPropertyForKey:@"t5"];
  
  // Then
  assertThat([customProperties properties], hasCountOf(5));
}

- (void)testSetString {
  
  // If
  NSString *key = @"test";
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Null value.
  // When
  NSString *nullValue = nil;
  [customProperties setString:nullValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Normal value.
  // When
  NSString *normalValue = @"test";
  [customProperties setString:normalValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(1));
}

- (void)testSetDate {
  
  // If
  NSString *key = @"test";
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Null value.
  // When
  NSDate *nullValue = nil;
  [customProperties setDate:nullValue forKey:key];
  assertThat([customProperties properties], hasCountOf(0));
  
  // Normal value.
  // When
  NSDate *normalValue = [NSDate dateWithTimeIntervalSince1970:0];
  [customProperties setDate:normalValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(1));
}

- (void)testSetNumber {
  
  // If
  NSString *key = @"test";
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Null value.
  // When
  NSNumber *nullValue = nil;
  [customProperties setNumber:nullValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Normal value.
  // When
  NSNumber *normalValue = @0;
  [customProperties setNumber:normalValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(1));
}

- (void)testSetBool {
  
  // If
  NSString *key = @"test";
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // Normal value.
  // When
  BOOL normalValue = NO;
  [customProperties setBool:normalValue forKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(1));
}

- (void)testClear {
  
  // If
  NSString *key = @"test";
  
  // When
  MSCustomProperties *customProperties = [MSCustomProperties new];
  
  // Then
  assertThat([customProperties properties], hasCountOf(0));
  
  // When
  [customProperties clearPropertyForKey:key];
  
  // Then
  assertThat([customProperties properties], hasCountOf(1));
}

@end
