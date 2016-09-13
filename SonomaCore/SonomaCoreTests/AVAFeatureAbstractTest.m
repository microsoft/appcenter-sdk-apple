#import "AVAAvalanche.h"
#import "AVAFeatureAbstract.h"
#import "AVAFeatureAbstractInternal.h"
#import "AVAFeatureAbstractPrivate.h"
#import "AVAUserDefaults.h"
#import "AVAUtils.h"
#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface AVAFeatureAbstractImplementation : AVAFeatureAbstract

@end

@implementation AVAFeatureAbstractImplementation

+ (instancetype)sharedInstance {
  static id sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (void) startFeature {
  [super startFeature];
}

- (NSString *)featureName {
  return @"AVAFeatureAbstractImplementation";
}

@end

@interface AVAFeatureAbstractTest : XCTestCase

@property(nonatomic) id settingsMock;

/**
 *  System Under test
 */
@property(nonatomic) AVAFeatureAbstractImplementation *abstractFeature;

@end

@implementation AVAFeatureAbstractTest

- (void)setUp {
  [super setUp];

  // Set up the mocked storage.
  self.settingsMock = OCMPartialMock(kAVAUserDefaults);

  // System Under Test.
  self.abstractFeature = [[AVAFeatureAbstractImplementation alloc] initWithStorage:self.settingsMock];

  // Clean storage.
  [(AVAUserDefaults *)self.settingsMock setObject:nil forKey:self.abstractFeature.isEnabledKey];
}

- (void)tearDown {
  [super tearDown];

  [self.settingsMock stopMocking];
}

- (void)testIsEnabledTrueByDefault {

  // When
  BOOL isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isTrue());
}

- (void)testSetEnabledToFalse {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:YES] forKey:self.abstractFeature.isEnabledKey];
  [self.abstractFeature setEnabled:NO];

  // When
  bool isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isFalse());
}

- (void)testSetEnabledToTrue {

  // If
  [self.settingsMock setObject:[NSNumber numberWithBool:NO] forKey:self.abstractFeature.isEnabledKey];
  [self.abstractFeature setEnabled:YES];

  // When
  bool isEnabled = [self.abstractFeature isEnabled];

  // Then
  assertThatBool(isEnabled, isTrue());
}

- (void)testIsEnabledToPersistence {

  /**
   *  If
   */
  __block NSNumber *isEnabled;
  BOOL expected = NO;

  // Mock AVASettings and swizzle its setObject:forKey: method to check what's sent by the sut to the persistence.
  OCMStub([self.settingsMock objectForKey:[OCMArg any]]).andReturn([NSNumber numberWithBool:YES]);
  OCMStub([self.settingsMock setObject:[OCMArg any] forKey:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
    [invocation getArgument:&isEnabled atIndex:2];
  });

  /**
   *  When
   */
  [self.abstractFeature setEnabled:expected];

  /**
   *  Then
   */
  assertThat(isEnabled, is([NSNumber numberWithBool:expected]));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock setObject:[OCMArg any] forKey:[OCMArg any]]);
}

- (void)testIsEnabledFromPersistence {

  /**
   *  If
   */
  NSNumber *expected = [NSNumber numberWithBool:NO];
  OCMStub([self.settingsMock objectForKey:[OCMArg any]]).andReturn(expected);

  /**
   *  When
   */
  BOOL isEnabled = [self.abstractFeature isEnabled];

  /**
   *  Then
   */
  assertThat([NSNumber numberWithBool:isEnabled], is(expected));

  // Also check that the sut did access the persistence.
  OCMVerify([self.settingsMock objectForKey:[OCMArg any]]);
}

- (void)testCanBeUsed {
  
//  AVAFeatureAbstractImplementation *sut = [AVAFeatureAbstractImplementation new];
  
  assertThatBool([[AVAFeatureAbstractImplementation sharedInstance] canBeUsed], isFalse());

  [AVAAvalanche start:[[NSUUID UUID] UUIDString] withFeatures:@[[AVAFeatureAbstractImplementation class]]];

  assertThatBool([[AVAFeatureAbstractImplementation sharedInstance] canBeUsed], isTrue());
}

@end
