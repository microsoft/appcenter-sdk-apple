#import "MSAppExtension.h"
#import "MSCSData.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSDeviceExtension.h"
#import "MSLocExtension.h"
#import "MSMetadataExtension.h"
#import "MSModelTestsUtililty.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSOrderedDictionaryPrivate.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSTestFrameworks.h"
#import "MSUserExtension.h"
#import "MSUtility.h"

@interface MSCSExtensionsTests : XCTestCase
@property(nonatomic) MSCSExtensions *ext;
@property(nonatomic) NSMutableDictionary *extDummyValues;
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
@property(nonatomic) NSMutableDictionary *sdkExtDummyValues;
@property(nonatomic) MSDeviceExtension *deviceExt;
@property(nonatomic) NSMutableDictionary *deviceExtDummyValues;
@property(nonatomic) MSMetadataExtension *metadataExt;
@property(nonatomic) NSDictionary *metadataExtDummyValues;
@property(nonatomic) MSCSData *data;
@property(nonatomic) NSDictionary *orderedDummyValues;
@property(nonatomic) NSDictionary *unorderedDummyValues;

@end

@implementation MSCSExtensionsTests

- (void)setUp {
  [super setUp];

  // Set up all extensions with dummy values.
  self.userExtDummyValues = [MSModelTestsUtililty userExtensionDummies];
  self.userExt = [MSModelTestsUtililty userExtensionWithDummyValues:self.userExtDummyValues];
  self.locExtDummyValues = [MSModelTestsUtililty locExtensionDummies];
  ;
  self.locExt = [MSModelTestsUtililty locExtensionWithDummyValues:self.locExtDummyValues];
  self.osExtDummyValues = [MSModelTestsUtililty osExtensionDummies];
  self.osExt = [MSModelTestsUtililty osExtensionWithDummyValues:self.osExtDummyValues];
  self.appExtDummyValues = [MSModelTestsUtililty appExtensionDummies];
  self.appExt = [MSModelTestsUtililty appExtensionWithDummyValues:self.appExtDummyValues];
  self.protocolExtDummyValues = [MSModelTestsUtililty protocolExtensionDummies];
  self.protocolExt = [MSModelTestsUtililty protocolExtensionWithDummyValues:self.protocolExtDummyValues];
  self.netExtDummyValues = [MSModelTestsUtililty netExtensionDummies];
  self.netExt = [MSModelTestsUtililty netExtensionWithDummyValues:self.netExtDummyValues];
  self.sdkExtDummyValues = [MSModelTestsUtililty sdkExtensionDummies];
  self.sdkExt = [MSModelTestsUtililty sdkExtensionWithDummyValues:self.sdkExtDummyValues];
  self.deviceExtDummyValues = [MSModelTestsUtililty deviceExtensionDummies];
  self.deviceExt = [MSModelTestsUtililty deviceExtensionWithDummyValues:self.deviceExtDummyValues];
  self.metadataExtDummyValues = [MSModelTestsUtililty metadataExtensionDummies];
  self.metadataExt = [MSModelTestsUtililty metadataExtensionWithDummyValues:self.metadataExtDummyValues];
  self.orderedDummyValues = [MSModelTestsUtililty orderedDataDummies];
  self.unorderedDummyValues = [MSModelTestsUtililty unorderedDataDummies];
  self.data = [MSModelTestsUtililty dataWithDummyValues:self.unorderedDummyValues];
  self.extDummyValues = [MSModelTestsUtililty extensionDummies];
  self.ext = [MSModelTestsUtililty extensionsWithDummyValues:self.extDummyValues];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - MSCSExtensions

- (void)testExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.ext serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict[kMSCSAppExt], [self.extDummyValues[kMSCSAppExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSNetExt], [self.extDummyValues[kMSCSNetExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSLocExt], [self.extDummyValues[kMSCSLocExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSSDKExt], [self.extDummyValues[kMSCSSDKExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSUserExt], [self.extDummyValues[kMSCSUserExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSProtocolExt], [self.extDummyValues[kMSCSProtocolExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSOSExt], [self.extDummyValues[kMSCSOSExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSDeviceExt], [self.extDummyValues[kMSCSDeviceExt] serializeToDictionary]);
  XCTAssertEqualObjects(dict[kMSCSMetadataExt], [self.extDummyValues[kMSCSMetadataExt] serializeToDictionary]);
}

- (void)testExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedExt = [NSKeyedArchiver archivedDataWithRootObject:self.ext];
  MSCSExtensions *actualExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedExt];

  // Then
  XCTAssertNotNil(actualExt);
  XCTAssertEqualObjects(self.ext, actualExt);
  XCTAssertTrue([actualExt isMemberOfClass:[MSCSExtensions class]]);
  XCTAssertEqualObjects(actualExt.metadataExt, self.extDummyValues[kMSCSMetadataExt]);
  XCTAssertEqualObjects(actualExt.userExt, self.extDummyValues[kMSCSUserExt]);
  XCTAssertEqualObjects(actualExt.locExt, self.extDummyValues[kMSCSLocExt]);
  XCTAssertEqualObjects(actualExt.appExt, self.extDummyValues[kMSCSAppExt]);
  XCTAssertEqualObjects(actualExt.protocolExt, self.extDummyValues[kMSCSProtocolExt]);
  XCTAssertEqualObjects(actualExt.osExt, self.extDummyValues[kMSCSOSExt]);
  XCTAssertEqualObjects(actualExt.netExt, self.extDummyValues[kMSCSNetExt]);
  XCTAssertEqualObjects(actualExt.sdkExt, self.extDummyValues[kMSCSSDKExt]);
}

- (void)testExtIsValid {

  // If
  MSCSExtensions *ext = [MSCSExtensions new];

  // Then
  XCTAssertTrue([ext isValid]);
}

- (void)testExtIsEqual {

  // If
  MSCSExtensions *anotherExt = [MSCSExtensions new];

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt = [MSModelTestsUtililty extensionsWithDummyValues:self.extDummyValues];

  // Then
  XCTAssertEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.metadataExt = OCMClassMock([MSMetadataExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.metadataExt = self.extDummyValues[kMSCSMetadataExt];
  anotherExt.userExt = OCMClassMock([MSUserExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.userExt = self.extDummyValues[kMSCSUserExt];
  anotherExt.locExt = OCMClassMock([MSLocExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.locExt = self.extDummyValues[kMSCSLocExt];
  anotherExt.osExt = OCMClassMock([MSOSExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.osExt = self.extDummyValues[kMSCSOSExt];
  anotherExt.appExt = OCMClassMock([MSAppExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.appExt = self.extDummyValues[kMSCSAppExt];
  anotherExt.protocolExt = OCMClassMock([MSProtocolExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.protocolExt = self.extDummyValues[kMSCSProtocolExt];
  anotherExt.netExt = OCMClassMock([MSNetExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);

  // If
  anotherExt.netExt = self.extDummyValues[kMSCSNetExt];
  anotherExt.sdkExt = OCMClassMock([MSSDKExtension class]);

  // Then
  XCTAssertNotEqualObjects(anotherExt, self.ext);
}

#pragma mark - MSMetadataExtension

- (void)testMetadataExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.metadataExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.metadataExtDummyValues);
}

- (void)testMetadataExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedMetadataExt = [NSKeyedArchiver archivedDataWithRootObject:self.metadataExt];
  MSMetadataExtension *actualMetadataExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedMetadataExt];

  // Then
  XCTAssertNotNil(actualMetadataExt);
  XCTAssertEqualObjects(self.metadataExt, actualMetadataExt);
  XCTAssertTrue([actualMetadataExt isMemberOfClass:[MSMetadataExtension class]]);
  XCTAssertEqualObjects(actualMetadataExt.metadata, self.metadataExtDummyValues);
}

- (void)testMetadataExtIsValid {

  // If
  MSMetadataExtension *metadataExt = [MSMetadataExtension new];

  // Then
  XCTAssertTrue([metadataExt isValid]);
}

- (void)testMetadataExtIsEqual {

  // If
  MSMetadataExtension *anotherMetadataExt = [MSMetadataExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherMetadataExt, self.metadataExt);

  // If
  anotherMetadataExt = [MSModelTestsUtililty metadataExtensionWithDummyValues:self.metadataExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherMetadataExt, self.metadataExt);

  // If
  anotherMetadataExt.metadata = @{};

  // Then
  XCTAssertNotEqualObjects(anotherMetadataExt, self.metadataExt);
}

#pragma mark - MSUserExtension

- (void)testUserExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.userExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict[kMSUserLocalId], self.userExtDummyValues[kMSUserLocalId]);
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
  XCTAssertEqualObjects(actualUserExt.localId, self.userExtDummyValues[kMSUserLocalId]);
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
  anotherUserExt = [MSModelTestsUtililty userExtensionWithDummyValues:self.userExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherUserExt, self.userExt);

  // If
  anotherUserExt.locale = @"fr-fr";

  // Then
  XCTAssertNotEqualObjects(anotherUserExt, self.userExt);

  // If
  anotherUserExt.locale = self.userExtDummyValues[kMSUserLocale];
  anotherUserExt.localId = @"42";

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
  XCTAssertEqualObjects(actualLocExt.tz, self.locExtDummyValues[kMSTimezone]);
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
  anotherLocExt = [MSModelTestsUtililty locExtensionWithDummyValues:self.locExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherLocExt, self.locExt);

  // If
  anotherLocExt.tz = @"+02:00";

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
  anotherOSExt = [MSModelTestsUtililty osExtensionWithDummyValues:self.osExtDummyValues];

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
  XCTAssertEqualObjects(actualAppExt.userId, self.appExtDummyValues[kMSAppUserId]);
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
  anotherAppExt = [MSModelTestsUtililty appExtensionWithDummyValues:self.appExtDummyValues];

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

  // If
  anotherAppExt.locale = self.appExtDummyValues[kMSAppLocale];
  anotherAppExt.userId = @"c:charlie";

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
  XCTAssertEqualObjects(actualProtocolExt.ticketKeys, self.protocolExtDummyValues[kMSTicketKeys]);
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
  anotherProtocolExt = [MSModelTestsUtililty protocolExtensionWithDummyValues:self.protocolExtDummyValues];

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
  anotherNetExt = [MSModelTestsUtililty netExtensionWithDummyValues:self.netExtDummyValues];

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
  self.sdkExtDummyValues[kMSSDKInstallId] = [((NSUUID *)self.sdkExtDummyValues[kMSSDKInstallId]) UUIDString];
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
  anotherSDKExt = [MSModelTestsUtililty sdkExtensionWithDummyValues:self.sdkExtDummyValues];

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
  anotherSDKExt.installId = [NSUUID new];

  // Then
  XCTAssertNotEqualObjects(anotherSDKExt, self.appExt);
}

#pragma mark - MSDeviceExtension

- (void)testDeviceExtJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.deviceExt serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.deviceExtDummyValues);
}

- (void)testDeviceExtNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedDeviceExt = [NSKeyedArchiver archivedDataWithRootObject:self.deviceExt];
  MSDeviceExtension *actualDeviceExt = [NSKeyedUnarchiver unarchiveObjectWithData:serializedDeviceExt];

  // Then
  XCTAssertNotNil(actualDeviceExt);
  XCTAssertEqualObjects(self.deviceExt, actualDeviceExt);
  XCTAssertTrue([actualDeviceExt isMemberOfClass:[MSDeviceExtension class]]);
  XCTAssertEqualObjects(actualDeviceExt.localId, self.deviceExtDummyValues[kMSDeviceLocalId]);
}

- (void)testDeviceExtIsValid {

  // When
  MSDeviceExtension *deviceExt = [MSDeviceExtension new];

  // Then
  XCTAssertTrue([deviceExt isValid]);
}

- (void)testDeviceExtIsEqual {

  // When
  MSDeviceExtension *anotherDeviceExt = [MSDeviceExtension new];

  // Then
  XCTAssertNotEqualObjects(anotherDeviceExt, self.deviceExt);

  // When
  anotherDeviceExt = [MSModelTestsUtililty deviceExtensionWithDummyValues:self.deviceExtDummyValues];

  // Then
  XCTAssertEqualObjects(anotherDeviceExt, self.deviceExt);

  // When
  anotherDeviceExt.localId = [[[NSUUID alloc] initWithUUIDString:@"11111111-1111-1111-1111-11111111111"] UUIDString];

  // Then
  XCTAssertNotEqualObjects(anotherDeviceExt, self.deviceExt);
}

#pragma mark - MSCSData

- (void)testDataJSONSerializingToDictionaryIsOrdered {

  // When
  MSOrderedDictionary *dict = (MSOrderedDictionary *)[self.data serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);

  // Only verify the order for baseType and baseData fields.
  XCTAssertTrue([dict.order[0] isEqualToString:@"baseType"]);
  XCTAssertTrue([dict.order[1] isEqualToString:@"baseData"]);
  XCTAssertEqualObjects(dict[@"aKey"], @"aValue");
  XCTAssertEqualObjects(dict[@"anested.key"], @"anothervalue");
  XCTAssertEqualObjects(dict[@"anotherkey"], @"yetanothervalue");
}

- (void)testDataNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedData = [NSKeyedArchiver archivedDataWithRootObject:self.data];
  MSCSData *actualData = [NSKeyedUnarchiver unarchiveObjectWithData:serializedData];

  // Then
  XCTAssertNotNil(actualData);
  XCTAssertEqualObjects(self.data, actualData);
  XCTAssertTrue([actualData isMemberOfClass:[MSCSData class]]);
  XCTAssertEqualObjects(actualData.properties, self.orderedDummyValues);
}

- (void)testDataIsValid {

  // If
  MSCSData *data = [MSCSData new];

  // Then
  XCTAssertTrue([data isValid]);
}

- (void)testDataIsEqual {

  // If
  MSCSData *anotherData = [MSCSData new];

  // Then
  XCTAssertNotEqualObjects(anotherData, self.data);

  // If
  anotherData = [MSModelTestsUtililty dataWithDummyValues:self.unorderedDummyValues];

  // Then
  XCTAssertEqualObjects(anotherData, self.data);

  // If
  anotherData.properties = [@{@"part.c.key" : @"part.c.value"} mutableCopy];

  // Then
  XCTAssertNotEqualObjects(anotherData, self.data);
}

@end
