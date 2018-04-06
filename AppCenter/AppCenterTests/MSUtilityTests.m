#import "MSConstants+Internal.h"
#import "MSTestFrameworks.h"
#import "MSUtility+ApplicationPrivate.h"
#import "MSUtility+Date.h"
#import "MSUtility+Environment.h"
#import "MSUtility+PropertyValidation.h"
#import "MSUtility+StringFormatting.h"

@interface MSUtilityTests : XCTestCase

@property(nonatomic) id utils;

@end

@implementation MSUtilityTests

- (void)setUp {
  [super setUp];

  // Set up application mock.
  self.utils = OCMClassMock([MSUtility class]);
}

- (void)tearDown {
  [super tearDown];
  [self.utils stopMocking];
}

#if !TARGET_OS_OSX
- (void)testMSAppStateMatchesUIAppStateWhenAvailable {

  // Then
  assertThat(@([MSUtility applicationState]), is(@([UIApplication sharedApplication].applicationState)));
}
#endif

- (void)testMSAppReturnsUnknownOnAppExtensions {

  // If
  // Mock the helper itself to monitor method calls.
  id bundleMock = OCMClassMock([NSBundle class]);
  OCMStub([bundleMock executablePath]).andReturn(@"/apath/coolappext.appex/coolappext");
  OCMStub([bundleMock mainBundle]).andReturn(bundleMock);
  OCMReject([self.utils sharedAppState]);

  // Then
  assertThat(@([MSUtility applicationState]), is(@(MSApplicationStateUnknown)));

  // Make sure the sharedApplication as not been called, it's forbidden within app extensions
  [bundleMock stopMocking];
}

- (void)testAppActive {

// If
#if TARGET_OS_OSX
  MSApplicationState expectedState = MSApplicationStateActive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);
#else
  UIApplicationState expectedState = UIApplicationStateActive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);
#endif

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

#if !TARGET_OS_OSX
- (void)testAppInactive {

  // If
  UIApplicationState expectedState = UIApplicationStateInactive;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}
#endif

- (void)testAppInBackground {

// If
#if TARGET_OS_OSX
  MSApplicationState expectedState = MSApplicationStateBackground;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);
#else
  UIApplicationState expectedState = UIApplicationStateBackground;
  OCMStub([self.utils sharedAppState]).andReturn(expectedState);
#endif

  // When
  MSApplicationState state = [MSUtility applicationState];

  // Then
  assertThat(@(state), is(@(expectedState)));
}

- (void)testNowInMilliseconds {

  // If
  NSDate *date = [NSDate date];
  id dateMock = OCMClassMock([NSDate class]);
  OCMStub([dateMock date]).andReturn(date);
  
  // When
  long long actual = (long long)([MSUtility nowInMilliseconds] / 10);
  long long expected = (long long)([[NSDate date] timeIntervalSince1970] * 100);

  // Then
  XCTAssertEqual(actual, expected);

  // Negative in case of cast issue.
  XCTAssertGreaterThan(actual, 0);
}

- (void)testCurrentAppEnvironment {

  // When
  MSEnvironment env = [MSUtility currentAppEnvironment];

  // Then
  // Tests always run in simulators.
  XCTAssertEqual(env, MSEnvironmentOther);
}

// FIXME: This method actually opens a dialog to ask to handle the URL on Mac.
#if !TARGET_OS_OSX
- (void)testSharedAppOpenEmptyCallCallback {

  // If
  XCTestExpectation *openURLCalledExpectation = [self expectationWithDescription:@"openURL Called."];
  __block BOOL handlerHasBeenCalled = NO;

  // When
  [MSUtility sharedAppOpenUrl:[NSURL URLWithString:@""]
      options:@{}
      completionHandler:^(MSOpenURLState status) {
        handlerHasBeenCalled = YES;
        XCTAssertEqual(status, MSOpenURLStateFailed);
      }];
  dispatch_async(dispatch_get_main_queue(), ^{
    [openURLCalledExpectation fulfill];
  });

  // Then
  [self waitForExpectationsWithTimeout:1
                               handler:^(NSError *error) {
                                 XCTAssertTrue(handlerHasBeenCalled);
                                 if (error) {
                                   XCTFail(@"Expectation Failed with error: %@", error);
                                 }
                               }];
}
#endif

- (void)testCreateSha256 {

  // When
  NSString *test = @"TestString";
  NSString *result = [MSUtility sha256:test];

  // Then
  XCTAssertTrue([result isEqualToString:@"6dd79f2770a0bb38073b814a5ff000647b37be5abbde71ec9176c6ce0cb32a27"]);
}

- (void)testSdkName {
  NSString *name = [NSString stringWithUTF8String:APP_CENTER_C_NAME];
  XCTAssertTrue([[MSUtility sdkName] isEqualToString:name]);
}

- (void)testSdkVersion {
  NSString *version = [NSString stringWithUTF8String:APP_CENTER_C_VERSION];
  XCTAssertTrue([[MSUtility sdkVersion] isEqualToString:version]);
}

- (void)testAppSecretFrom {
  
  // When
  NSString *uuidString = MS_UUID_STRING;
  
  // Then
  NSString *result = [MSUtility appSecretFrom:uuidString];
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  NSString *test = nil;
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNil(result);
  
  // When
  test = [NSString stringWithFormat:@"%@;", uuidString];
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"%@;target={transmissionTargetToken}", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"%@;target={transmissionTargetToken};", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"target={transmissionTargetToken};%@", uuidString];
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"target={transmissionTargetToken};%@;", uuidString];
  
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = @"target={transmissionTargetToken}";
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNil(result);
  
  // When
  test = @"target={transmissionTargetToken};";
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNil(result);
  
  // When
  test = [NSString stringWithFormat:@"appsecret=%@;target={transmissionTargetToken};", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"appsecret=%@;", uuidString];
  result = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"appsecret=%@", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"target={transmissionTargetToken};appsecret=%@;", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);

  // When
  test = [NSString stringWithFormat:@"target={transmissionTargetToken};appsecret=%@", uuidString];
  result = [MSUtility appSecretFrom:test];

  // Then
  XCTAssertTrue([uuidString isEqualToString:result]);
}

- (void)testTransmissionTokenFrom {
  
  // When
  NSString *test = @"{app-secret}";
  
  // Then
  NSString *result = [MSUtility transmissionTargetTokenFrom:test];
  XCTAssertNil(result);

  // When
  test = nil;
  result = [MSUtility transmissionTargetTokenFrom:test];

  // Then
  XCTAssertNil(result);

  // When
  test = @"{app-secret};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertNil(result);

  // When
  test = @"{app-secret};target={transmissionTargetToken}";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);
  
  // When
  test = @"{app-secret};target={transmissionTargetToken};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"target={transmissionTargetToken};{app-secret}";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"target={transmissionTargetToken};{app-secret};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"target={transmissionTargetToken}";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"target={transmissionTargetToken};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);
  
  // When
  test = @"appsecret={app-secret};target={transmissionTargetToken};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"appsecret={app-secret};";
  result = [MSUtility transmissionTargetTokenFrom:test];

  // Then
  XCTAssertNil(result);
  
  // When
  test = @"appsecret={app-secret}";
  result = [MSUtility transmissionTargetTokenFrom:test];

  // Then
  XCTAssertNil(result);
  
  // When
  test = @"target={transmissionTargetToken};appsecret={app-secret};";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);

  // When
  test = @"target={transmissionTargetToken};appsecret={app-secret}";
  result = [MSUtility transmissionTargetTokenFrom:test];
  
  // Then
  XCTAssertTrue([result isEqualToString:@"{transmissionTargetToken}"]);
}

- (void)testInvalidSecretOrTokenInput {
  
  // When
  NSString *guidString = @"{app-secret}";
  NSString *test = [NSString stringWithFormat:@"target=;appsecret=%@", guidString];
  NSString *tokenResult = [MSUtility transmissionTargetTokenFrom:test];
  NSString *secretResult = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNil(tokenResult);
  XCTAssertTrue([guidString isEqualToString:secretResult]);

  // When
  test = @"target=;target=;appsecret=;appsecret=;";
  tokenResult = [MSUtility transmissionTargetTokenFrom:test];
  secretResult = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNil(tokenResult);
  XCTAssertNil(secretResult);
  
  // When
  guidString = MS_UUID_STRING;
  test = [NSString stringWithFormat:@"target=;target={transmissionTargetToken};appsecret=;appsecret=%@;", guidString];
  tokenResult = [MSUtility transmissionTargetTokenFrom:test];
  secretResult = [MSUtility appSecretFrom:test];
  
  // Then
  XCTAssertNotNil(secretResult);
  XCTAssertTrue([guidString isEqualToString:secretResult]);
  XCTAssertTrue([tokenResult isEqualToString:@"{transmissionTargetToken}"]);
}

- (void)testValidatePropertyType {
  NSString *longStringValue =
  [@"" stringByPaddingToLength:(kMSMaxPropertyValueLength + 1) withString:@"value" startingAtIndex:0];
  NSString *stringValue125 =
  [@"" stringByPaddingToLength:kMSMaxPropertyValueLength withString:@"value" startingAtIndex:0];
  NSString *testLogTag = @"MSUtilityTests";
  NSString *testLogTypeString = @"testLog";

  // Test valid properties
  // If
  NSDictionary *validProperties = @{
                                    @"Key1" : @"Value1",
                                    stringValue125 : @"Value2",
                                    @"Key3" : stringValue125,
                                    @"Key4" : @"Value4",
                                    @"Key5" : @""
                                    };
  
  // When
  NSDictionary *validatedProperties = [MSUtility validateProperties:validProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  XCTAssertTrue([validatedProperties count] == [validProperties count]);
  
  // Test too many properties in one event
  // If
  NSDictionary *tooManyProperties = @{
                                      @"Key1" : @"Value1",
                                      @"Key2" : @"Value2",
                                      @"Key3" : @"Value3",
                                      @"Key4" : @"Value4",
                                      @"Key5" : @"Value5",
                                      @"Key6" : @"Value6",
                                      @"Key7" : @"Value7",
                                      @"Key8" : @"Value8",
                                      @"Key9" : @"Value9",
                                      @"Key10" : @"Value10",
                                      @"Key11" : @"Value11",
                                      @"Key12" : @"Value12",
                                      @"Key13" : @"Value13",
                                      @"Key14" : @"Value14",
                                      @"Key15" : @"Value15",
                                      @"Key16" : @"Value16",
                                      @"Key17" : @"Value17",
                                      @"Key18" : @"Value18",
                                      @"Key19" : @"Value19",
                                      @"Key20" : @"Value20",
                                      @"Key21" : @"Value21",
                                      @"Key22" : @"Value22"
                                      };
  
  // When
  validatedProperties =
  [MSUtility validateProperties:tooManyProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  XCTAssertTrue([validatedProperties count] == kMSMaxPropertiesPerLog);
  
  // Test invalid properties
  // If
  NSDictionary *invalidKeysInProperties = @{ @"Key1" : @"Value1", @(2) : @"Value2", @"" : @"Value4" };
  
  // When
  validatedProperties = [MSUtility validateProperties:invalidKeysInProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  XCTAssertTrue([validatedProperties count] == 1);
  
  // Test invalid values
  // If
  NSDictionary *invalidValuesInProperties = @{ @"Key1" : @"Value1", @"Key2" : @(2) };
  
  // When
  validatedProperties = [MSUtility validateProperties:invalidValuesInProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  XCTAssertTrue([validatedProperties count] == 1);
  
  // Test long keys and values are truncated.
  // If
  NSDictionary *tooLongKeysAndValuesInProperties = @{longStringValue : longStringValue};
  
  // When
  validatedProperties = [MSUtility validateProperties:tooLongKeysAndValuesInProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  NSString *truncatedKey = (NSString *)[[validatedProperties allKeys] firstObject];
  NSString *truncatedValue = (NSString *)[[validatedProperties allValues] firstObject];
  XCTAssertTrue([validatedProperties count] == 1);
  XCTAssertEqual([truncatedKey length], kMSMaxPropertyKeyLength);
  XCTAssertEqual([truncatedValue length], kMSMaxPropertyValueLength);
  
  // Test mixed variant
  // If
  NSDictionary *mixedProperties = @{
                                    @"Key1" : @"Value1",
                                    @(2) : @"Value2",
                                    stringValue125 : @"Value3",
                                    @"Key4" : stringValue125,
                                    @"Key5" : @"Value5",
                                    @"Key6" : @(2),
                                    @"Key7" : longStringValue,
                                    @"Key8" : @"Value8",
                                    @(2) : @"Value9",
                                    stringValue125 : @"Value10",
                                    @"Key11" : stringValue125,
                                    @"Key12" : @"Value12",
                                    @"Key13" : @(2),
                                    @"Key14" : longStringValue,
                                    @"Key15" : @"Value15",
                                    @(2) : @"Value16",
                                    stringValue125 : @"Value17",
                                    @"Key18" : stringValue125,
                                    @"Key19" : @"Value19",
                                    @"Key20" : @(2),
                                    @"Key21" : longStringValue,
                                    @"Key22" : @"Value22",
                                    @(2) : @"Value23",
                                    stringValue125 : @"Value124",
                                    @"Key25" : stringValue125,
                                    @"Key26" : @"Value26",
                                    @"Key27" : @(2),
                                    @"Key28" : @"Value28",
                                    @(2) : @"Value29",
                                    stringValue125 : @"Value30",
                                    @"Key31" : stringValue125,
                                    @"Key32" : @"Value32",
                                    @"Key33" : @(2),
                                    @"Key34" : longStringValue,
                                    };
  
  // When
  validatedProperties =[MSUtility validateProperties:mixedProperties forLogName:testLogTypeString type:testLogTypeString withConsoleLogTag:testLogTag];
  
  // Then
  XCTAssertTrue([validatedProperties count] == kMSMaxPropertiesPerLog);
  XCTAssertNotNil([validatedProperties objectForKey:@"Key1"]);
  XCTAssertNotNil([validatedProperties objectForKey:stringValue125]);
  XCTAssertNotNil([validatedProperties objectForKey:@"Key4"]);
  XCTAssertNotNil([validatedProperties objectForKey:@"Key5"]);
  XCTAssertNil([validatedProperties objectForKey:@"Key6"]);
  XCTAssertNotNil([validatedProperties objectForKey:@"Key7"]);
}

@end
