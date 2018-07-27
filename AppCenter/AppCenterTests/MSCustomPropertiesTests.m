#import <Foundation/Foundation.h>

#import "MSCustomProperties.h"
#import "MSCustomPropertiesPrivate.h"
#import "MSTestFrameworks.h"

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

  // Too long key.
  // When
  NSString *tooLongKey =
      [@"" stringByPaddingToLength:129 withString:@"a" startingAtIndex:0];
  [customProperties setString:string forKey:tooLongKey];
  [customProperties setDate:date forKey:tooLongKey];
  [customProperties setNumber:number forKey:tooLongKey];
  [customProperties setBool:boolean forKey:tooLongKey];
  [customProperties clearPropertyForKey:tooLongKey];

  // Then
  assertThat([customProperties properties], hasCountOf(0));

  // Normal keys.
  // When
  NSString *maxLongKey =
      [@"" stringByPaddingToLength:128 withString:@"a" startingAtIndex:0];
  [customProperties setString:string forKey:@"t1"];
  [customProperties setDate:date forKey:@"t2"];
  [customProperties setNumber:number forKey:@"t3"];
  [customProperties setBool:boolean forKey:@"t4"];
  [customProperties clearPropertyForKey:@"t5"];
  [customProperties setString:string forKey:maxLongKey];

  // Then
  assertThat([customProperties properties], hasCountOf(6));

  // Already contains keys.
  // When
  [customProperties setString:string forKey:@"t1"];
  [customProperties setDate:date forKey:@"t2"];
  [customProperties setNumber:number forKey:@"t3"];
  [customProperties setBool:boolean forKey:@"t4"];
  [customProperties clearPropertyForKey:@"t5"];
  [customProperties setString:string forKey:maxLongKey];

  // Then
  assertThat([customProperties properties], hasCountOf(6));
}

- (void)testMaxPropertiesCount {

  // If
  const int maxPropertiesCount = 60;
  MSCustomProperties *customProperties = [MSCustomProperties new];

  // Maximum properties count.
  // When
  for (int i = 0; i < maxPropertiesCount; i++) {
    [customProperties setNumber:@(i)
                         forKey:[NSString stringWithFormat:@"key%d", i]];
  }

  // Then
  assertThat([customProperties properties], hasCountOf(maxPropertiesCount));

  // Exceeding maximum properties count.
  // When
  [customProperties setNumber:@(1) forKey:@"extra1"];

  // Then
  assertThat([customProperties properties], hasCountOf(maxPropertiesCount));

  // When
  [customProperties setNumber:@(1) forKey:@"extra2"];

  // Then
  assertThat([customProperties properties], hasCountOf(maxPropertiesCount));
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

  // Too long value.
  // When
  NSString *tooLongValue =
      [@"" stringByPaddingToLength:129 withString:@"a" startingAtIndex:0];
  [customProperties setString:tooLongValue forKey:key];

  // Then
  assertThat([customProperties properties], hasCountOf(0));

  // Empty value.
  // When
  NSString *emptyValue = @"";
  [customProperties setString:emptyValue forKey:key];

  // Then
  assertThat([customProperties properties], hasCountOf(1));
  assertThat([customProperties properties][key], is(emptyValue));

  // Normal value.
  // When
  NSString *normalValue = @"test";
  [customProperties setString:normalValue forKey:key];

  // Then
  assertThat([customProperties properties], hasCountOf(1));
  assertThat([customProperties properties][key], is(normalValue));

  // Normal value with maximum length.
  // When
  NSString *maxLongValue =
      [@"" stringByPaddingToLength:128 withString:@"a" startingAtIndex:0];
  [customProperties setString:maxLongValue forKey:key];

  // Then
  assertThat([customProperties properties], hasCountOf(1));
  assertThat([customProperties properties][key], is(maxLongValue));
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
  assertThat([customProperties properties][key], is(normalValue));
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
  assertThat([customProperties properties][key], is(normalValue));
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
  assertThat([customProperties properties][key], is(@(normalValue)));
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
  assertThat([customProperties properties][key], is([NSNull null]));
}

@end
