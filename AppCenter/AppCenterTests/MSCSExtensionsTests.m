#import "MSAppExtension.h"
#import "MSCSConstants.h"
#import "MSCSData.h"
#import "MSLocExtension.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSTestFrameworks.h"
#import "MSUserExtension.h"

@interface MSCSExtensionsTests : XCTestCase
@property(nonatomic) MSUserExtension *userExt;
@property(nonatomic) NSDictionary *userExtDummyValues;
@property(nonatomic) MSLocExtension *locExt;
@property(nonatomic) NSDictionary *locExtDummyValues;
@property(nonatomic) MSOSExtension *osExt;
@property(nonatomic) NSDictionary *osExtDummyValues;
@property(nonatomic) MSAppExtension *appExt;
@property(nonatomic) NSDictionary *appExtDummyValues;
@property(nonatomic) MSProtocolExtension *protocolExt;
@property(nonatomic) NSDictionary *protocolExtDummyValues;
@property(nonatomic) MSNetExtension *netExt;
@property(nonatomic) NSDictionary *netExtDummyValues;
@property(nonatomic) MSSDKExtension *sdkExt;
@property(nonatomic) NSDictionary *sdkExtDummyValues;
@property(nonatomic) MSCSData *data;
@property(nonatomic) NSDictionary *dataDummyValues;
@end

@implementation MSCSExtensionsTests

- (void)setUp {
  [super setUp];
  self.userExtDummyValues = @{ kMSUserLocale : @"en-us" };
  self.userExt = [self userExtensionWithDummyValues:self.userExtDummyValues];
  self.locExtDummyValues = @{ kMSTimezone : @"-03:00" };
  self.locExt = [self locExtensionWithDummyValues:self.locExtDummyValues];
  self.osExtDummyValues = @{ kMSOSName : @"iOS", kMSOSVer : @"9.0" };
  self.osExt = [self osExtensionWithDummyValues:self.osExtDummyValues];
  self.appExtDummyValues = @{ kMSAppId : @"com.some.bundle.id", kMSAppVer : @"3.4.1", kMSAppLocale : @"en-us" };
  self.appExt = [self appExtensionWithDummyValues:self.appExtDummyValues];
  self.protocolExtDummyValues = @{ kMSDevMake : @"Apple", kMSDevModel : @"iPhone X" };
  self.protocolExt = [self protocolExtensionWithDummyValues:self.protocolExtDummyValues];
  self.netExtDummyValues = @{ kMSNetProvider : @"Verizon" };
  self.netExt = [self netExtensionWithDummyValues:self.netExtDummyValues];
  self.sdkExtDummyValues = @{
    kMSSDKLibVer : @"1.2.0",
    kMSSDKEpoch : @"epoch_value",
    kMSSDKSeq : @1,
    kMSSDKInstallId : @"41b61ab0-5fbc-11e8-9c2d-fa7ae01bbebc"
  };
  self.sdkExt = [self sdkExtensionWithDummyValues:self.sdkExtDummyValues];
}

#pragma mark - MSUserExtension

- (void)testUserExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.userExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict[kMSUserLocale], self.userExtDummyValues[kMSUserLocale]);
}

- (void)testUserExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedUserExt = [NSKeyedArchiver archivedDataWithRootObject:self.userExt];
  MSUserExtension *actualUserExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedUserExt];

  // Then
  XCTAssertNotNil(actualUserExt);
  XCTAssertEqualObjects(self.userExt, actualUserExt);
  XCTAssertTrue([actualUserExt isMemberOfClass:[MSUserExtension class]]);
  XCTAssertEqualObjects(actualUserExt.locale, self.userExtDummyValues[kMSUserLocale]);
}

- (void)testUserExtIsValid {

  // If
  MSUserExtension *userExt = [MSUserExtension new];

  // Then
  XCTAssertTrue([userExt isValid]);
}

- (void)testUserExtIsEqual {

  // If
  MSUserExtension *anotherUserExt = [MSUserExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherUserExt, self.userExt);

  // If
  anotherUserExt = [self userExtensionWithDummyValues:self.userExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherUserExt, self.userExt);

  // If
  anotherUserExt.locale = @"fr-fr";

  // Then
  XCTAssertNotEqualObjects(anotherUserExt, self.userExt);
}

#pragma mark - MSLocExtension

- (void)testLocExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.locExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict[kMSTimezone], self.locExtDummyValues[kMSTimezone]);
}

- (void)testLocExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedlocExt = [NSKeyedArchiver archivedDataWithRootObject:self.locExt];
  MSLocExtension *actualLocExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedlocExt];

  // Then
  XCTAssertNotNil(actualLocExt);
  XCTAssertEqualObjects(self.locExt, actualLocExt);
  XCTAssertTrue([actualLocExt isMemberOfClass:[MSLocExtension class]]);
  XCTAssertEqualObjects(actualLocExt.timezone, self.locExtDummyValues[kMSTimezone]);
}

- (void)testLocExtIsValid {

  // If
  MSLocExtension *locExt = [MSLocExtension new];

  // Then
  XCTAssertTrue([locExt isValid]);
}

- (void)testLocExtIsEqual {

  // If
  MSLocExtension *anotherLocExt = [MSLocExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherLocExt, self.locExt);

  // If
  anotherLocExt = [self locExtensionWithDummyValues:self.locExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherLocExt, self.locExt);

  // If
  anotherLocExt.timezone = @"+02:00";

  // Then
  XCTAssertNotEqualObjects(anotherLocExt, self.locExt);
}

#pragma mark - MSOSExtension

- (void)testOSExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.osExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.osExtDummyValues);
}

- (void)testOSExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedOSExt = [NSKeyedArchiver archivedDataWithRootObject:self.osExt];
  MSOSExtension *actualOSExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedOSExt];

  // Then
  XCTAssertNotNil(actualOSExt);
  XCTAssertEqualObjects(self.osExt, actualOSExt);
  XCTAssertTrue([actualOSExt isMemberOfClass:[MSOSExtension class]]);
  XCTAssertEqualObjects(actualOSExt.name, self.osExtDummyValues[kMSOSName]);
  XCTAssertEqualObjects(actualOSExt.ver, self.osExtDummyValues[kMSOSVer]);
}

- (void)testOSExtIsValid {

  // If
  MSOSExtension *osExt = [MSOSExtension new];

  // Then
  XCTAssertTrue([osExt isValid]);
}

- (void)testOSExtIsEqual {

  // If
  MSOSExtension *anotherOSExt = [MSOSExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherOSExt, self.osExt);

  // If
  anotherOSExt = [self osExtensionWithDummyValues:self.osExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherOSExt, self.osExt);

  // If
  anotherOSExt.name = @"macOS";

  // Then
  XCTAssertNotEqualObjects(anotherOSExt, self.osExt);

  // If
  anotherOSExt.name = self.osExtDummyValues[kMSOSName];
  anotherOSExt.ver = @"10.13.4";

  // Then
  XCTAssertNotEqualObjects(anotherOSExt, self.osExt);
}

#pragma mark - MSAppExtension

- (void)testAppExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.appExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.appExtDummyValues);
}

- (void)testAppExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedAppExt = [NSKeyedArchiver archivedDataWithRootObject:self.appExt];
  MSAppExtension *actualAppExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedAppExt];

  // Then
  XCTAssertNotNil(actualAppExt);
  XCTAssertEqualObjects(self.appExt, actualAppExt);
  XCTAssertTrue([actualAppExt isMemberOfClass:[MSAppExtension class]]);
  XCTAssertEqualObjects(actualAppExt.appId, self.appExtDummyValues[kMSAppId]);
  XCTAssertEqualObjects(actualAppExt.ver, self.appExtDummyValues[kMSAppVer]);
  XCTAssertEqualObjects(actualAppExt.locale, self.appExtDummyValues[kMSAppLocale]);
}

- (void)testAppExtIsValid {

  // If
  MSAppExtension *appExt = [MSAppExtension new];

  // Then
  XCTAssertTrue([appExt isValid]);
}

- (void)testAppExtIsEqual {

  // If
  MSAppExtension *anotherAppExt = [MSAppExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherAppExt, self.appExt);

  // If
  anotherAppExt = [self appExtensionWithDummyValues:self.appExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherAppExt, self.appExt);

  // If
  anotherAppExt.appId = @"com.another.bundle.id";

  // Then
  XCTAssertNotEqualObjects(anotherAppExt, self.appExt);

  // If
  anotherAppExt.appId = self.appExtDummyValues[kMSAppId];
  anotherAppExt.ver = @"10.13.4";

  // Then
  XCTAssertNotEqualObjects(anotherAppExt, self.appExt);

  // If
  anotherAppExt.ver = self.appExtDummyValues[kMSAppVer];
  anotherAppExt.locale = @"fr-ca";

  // Then
  XCTAssertNotEqualObjects(anotherAppExt, self.appExt);
}

#pragma mark - MSProtocolExtension

- (void)testProtocolExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.protocolExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.protocolExtDummyValues);
}

- (void)testProtocolExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedProtocolExt = [NSKeyedArchiver archivedDataWithRootObject:self.protocolExt];
  MSProtocolExtension *actualProtocolExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedProtocolExt];

  // Then
  XCTAssertNotNil(actualProtocolExt);
  XCTAssertEqualObjects(self.protocolExt, actualProtocolExt);
  XCTAssertTrue([actualProtocolExt isMemberOfClass:[MSProtocolExtension class]]);
  XCTAssertEqualObjects(actualProtocolExt.devMake, self.protocolExtDummyValues[kMSDevMake]);
  XCTAssertEqualObjects(actualProtocolExt.devModel, self.protocolExtDummyValues[kMSDevModel]);
}

- (void)testProtocolExtIsValid {

  // If
  MSProtocolExtension *protocolExt = [MSProtocolExtension new];

  // Then
  XCTAssertTrue([protocolExt isValid]);
}

- (void)testProtocolExtIsEqual {

  // If
  MSProtocolExtension *anotherProtocolExt = [MSProtocolExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherProtocolExt, self.protocolExt);

  // If
  anotherProtocolExt = [self protocolExtensionWithDummyValues:self.protocolExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherProtocolExt, self.protocolExt);

  // If
  anotherProtocolExt.devMake = @"Android";

  // Then
  XCTAssertNotEqualObjects(anotherProtocolExt, self.protocolExt);

  // If
  anotherProtocolExt.devMake = self.protocolExtDummyValues[kMSDevMake];
  anotherProtocolExt.devModel = @"Samsung Galaxy 8";

  // Then
  XCTAssertNotEqualObjects(anotherProtocolExt, self.protocolExt);
}

#pragma mark - MSNetExtension

- (void)testNetExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.netExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.netExtDummyValues);
}

- (void)testNetExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedNetExt = [NSKeyedArchiver archivedDataWithRootObject:self.netExt];
  MSNetExtension *actualNetExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedNetExt];

  // Then
  XCTAssertNotNil(actualNetExt);
  XCTAssertEqualObjects(self.netExt, actualNetExt);
  XCTAssertTrue([actualNetExt isMemberOfClass:[MSNetExtension class]]);
  XCTAssertEqualObjects(actualNetExt.provider, self.netExtDummyValues[kMSNetProvider]);
}

- (void)testNetExtIsValid {

  // If
  MSNetExtension *netExt = [MSNetExtension new];

  // Then
  XCTAssertTrue([netExt isValid]);
}

- (void)testNetExtIsEqual {

  // If
  MSNetExtension *anotherNetExt = [MSNetExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherNetExt, self.netExt);

  // If
  anotherNetExt = [self netExtensionWithDummyValues:self.netExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherNetExt, self.netExt);

  // If
  anotherNetExt.provider = @"Sprint";

  // Then
  XCTAssertNotEqualObjects(anotherNetExt, self.netExt);
}

#pragma mark - MSSDKExtension

- (void)testSDKExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.sdkExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.sdkExtDummyValues);
}

- (void)testSDKExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedSDKExt = [NSKeyedArchiver archivedDataWithRootObject:self.sdkExt];
  MSSDKExtension *actualSDKExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedSDKExt];

  // Then
  XCTAssertNotNil(actualSDKExt);
  XCTAssertEqualObjects(self.sdkExt, actualSDKExt);
  XCTAssertTrue([actualSDKExt isMemberOfClass:[MSSDKExtension class]]);
  XCTAssertEqualObjects(actualSDKExt.libVer, self.sdkExtDummyValues[kMSSDKLibVer]);
  XCTAssertEqualObjects(actualSDKExt.epoch, self.sdkExtDummyValues[kMSSDKEpoch]);
  XCTAssertTrue(actualSDKExt.seq == [self.sdkExtDummyValues[kMSSDKSeq] longLongValue]);
  XCTAssertEqualObjects(actualSDKExt.installId, self.sdkExtDummyValues[kMSSDKInstallId]);
}

- (void)testSDKExtIsValid {

  // If
  MSSDKExtension *sdkExt = [MSSDKExtension new];

  // Then
  XCTAssertTrue([sdkExt isValid]);
}

- (void)testSDKExtIsEqual {

  // If
  MSSDKExtension *anotherSDKExt = [MSSDKExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.sdkExt);

  // If
  anotherSDKExt = [self sdkExtensionWithDummyValues:self.sdkExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherSDKExt, self.sdkExt);

  // If
  anotherSDKExt.libVer = @"2.1.0";

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.sdkExt);

  // If
  anotherSDKExt.libVer = self.sdkExtDummyValues[kMSSDKLibVer];
  anotherSDKExt.epoch = @"other_epoch_value";

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.sdkExt);

  // If
  anotherSDKExt.epoch = self.sdkExtDummyValues[kMSSDKEpoch];
  anotherSDKExt.seq = 2;

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.sdkExt);

  // If
  anotherSDKExt.seq = [self.sdkExtDummyValues[kMSSDKSeq] longLongValue];
  anotherSDKExt.installId = @"8caf7096-5fbe-11e8-9c2d-fa7ae01bbebc";

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.appExt);
}

#pragma mark - Helper

- (MSUserExtension *)userExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSUserExtension *userExt = [MSUserExtension new];
  userExt.locale = dummyValues[kMSUserLocale];
  return userExt;
}

- (MSLocExtension *)locExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSLocExtension *locExt = [MSLocExtension new];
  locExt.timezone = dummyValues[kMSTimezone];
  return locExt;
}

- (MSOSExtension *)osExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSOSExtension *osExt = [MSOSExtension new];
  osExt.name = dummyValues[kMSOSName];
  osExt.ver = dummyValues[kMSOSVer];
  return osExt;
}

- (MSAppExtension *)appExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSAppExtension *appExt = [MSAppExtension new];
  appExt.appId = dummyValues[kMSAppId];
  appExt.ver = dummyValues[kMSAppVer];
  appExt.locale = dummyValues[kMSAppLocale];
  return appExt;
}

- (MSProtocolExtension *)protocolExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSProtocolExtension *protocolExt = [MSProtocolExtension new];
  protocolExt.devMake = dummyValues[kMSDevMake];
  protocolExt.devModel = dummyValues[kMSDevModel];
  return protocolExt;
}

- (MSNetExtension *)netExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSNetExtension *netExt = [MSNetExtension new];
  netExt.provider = dummyValues[kMSNetProvider];
  return netExt;
}

- (MSSDKExtension *)sdkExtensionWithDummyValues:(NSDictionary *)dummyValues {
  MSSDKExtension *sdkExt = [MSSDKExtension new];
  sdkExt.libVer = dummyValues[kMSSDKLibVer];
  sdkExt.epoch = dummyValues[kMSSDKEpoch];
  sdkExt.seq = [dummyValues[kMSSDKSeq] longLongValue];
  sdkExt.installId = dummyValues[kMSSDKInstallId];
  return sdkExt;
}

@end
