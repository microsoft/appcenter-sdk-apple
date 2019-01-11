#import "MSACModelConstants.h"
#import "MSAppExtension.h"
#import "MSCSData.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSCommonSchemaLog.h"
#import "MSConstants.h"
#import "MSDevice.h"
#import "MSLocExtension.h"
#import "MSLogContainer.h"
#import "MSModelTestsUtililty.h"
#import "MSNetExtension.h"
#import "MSOSExtension.h"
#import "MSProtocolExtension.h"
#import "MSSDKExtension.h"
#import "MSTestFrameworks.h"
#import "MSUserExtension.h"
#import "MSUtility+Date.h"

@interface MSCommonSchemaLogTests : XCTestCase
@property(nonatomic) MSCommonSchemaLog *commonSchemaLog;
@property(nonatomic) NSMutableDictionary *csLogDummyValues;
@end

@implementation MSCommonSchemaLogTests

- (void)setUp {
  [super setUp];
  id device = OCMClassMock([MSDevice class]);
  OCMStub([device isValid]).andReturn(YES);
  NSDictionary *abstractDummies = [MSModelTestsUtililty abstractLogDummies];
  self.csLogDummyValues = [@{
    kMSCSVer : @"3.0",
    kMSCSName : @"1DS",
    kMSCSTime : abstractDummies[kMSTimestamp],
    kMSCSIKey : @"o:60cd0b94-6060-11e8-9c2d-fa7ae01bbebc",
    kMSCSFlags : @(MSFlagsPersistenceNormal),
    kMSCSExt : [self extWithDummyValues],
    kMSCSData : [self dataWithDummyValues]
  } mutableCopy];
  [self.csLogDummyValues addEntriesFromDictionary:abstractDummies];
  self.commonSchemaLog = [self csLogWithDummyValues:self.csLogDummyValues];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - MSCommonSchemaLog

- (void)testCSLogJSONSerializingToDictionary {

  // If
  MSOrderedDictionary *expectedSerializedLog = [MSOrderedDictionary new];
  [expectedSerializedLog setObject:@"3.0" forKey:kMSCSVer];
  [expectedSerializedLog setObject:@"1DS" forKey:kMSCSName];
  [expectedSerializedLog setObject:[MSUtility dateToISO8601:self.csLogDummyValues[kMSCSTime]] forKey:kMSCSTime];
  [expectedSerializedLog setObject:@"o:60cd0b94-6060-11e8-9c2d-fa7ae01bbebc" forKey:kMSCSIKey];
  [expectedSerializedLog setObject:@(MSFlagsPersistenceNormal) forKey:kMSCSFlags];
  [expectedSerializedLog setObject:[self.csLogDummyValues[kMSCSExt] serializeToDictionary] forKey:kMSCSExt];
  [expectedSerializedLog setObject:[self.csLogDummyValues[kMSCSData] serializeToDictionary] forKey:kMSCSData];

  // When
  NSMutableDictionary *serializedLog = [self.commonSchemaLog serializeToDictionary];

  // Then
  XCTAssertNotNil(serializedLog);
  XCTAssertTrue([expectedSerializedLog isEqualToDictionary:serializedLog]);
}

- (void)testCSLogNSCodingSerializationAndDeserialization {

  // When
  NSData *serializedCSLog = [NSKeyedArchiver archivedDataWithRootObject:self.commonSchemaLog];
  MSCommonSchemaLog *actualCSLog = [NSKeyedUnarchiver unarchiveObjectWithData:serializedCSLog];

  // Then
  XCTAssertNotNil(actualCSLog);
  XCTAssertEqualObjects(self.commonSchemaLog, actualCSLog);
  XCTAssertTrue([actualCSLog isMemberOfClass:[MSCommonSchemaLog class]]);
  XCTAssertEqualObjects(actualCSLog.ver, self.csLogDummyValues[kMSCSVer]);
  XCTAssertEqualObjects(actualCSLog.name, self.csLogDummyValues[kMSCSName]);
  XCTAssertEqualObjects(actualCSLog.timestamp, self.csLogDummyValues[kMSCSTime]);
  XCTAssertEqual(actualCSLog.popSample, [self.csLogDummyValues[kMSCSPopSample] doubleValue]);
  XCTAssertEqualObjects(actualCSLog.iKey, self.csLogDummyValues[kMSCSIKey]);
  XCTAssertEqual(actualCSLog.flags, [self.csLogDummyValues[kMSCSFlags] longLongValue]);
  XCTAssertEqualObjects(actualCSLog.cV, self.csLogDummyValues[kMSCSCV]);
  XCTAssertEqualObjects(actualCSLog.ext, self.csLogDummyValues[kMSCSExt]);
  XCTAssertEqualObjects(actualCSLog.data, self.csLogDummyValues[kMSCSData]);
}

- (void)testCSLogIsValid {

  // If
  MSCommonSchemaLog *csLog = [MSCommonSchemaLog new];

  // Then
  XCTAssertFalse([csLog isValid]);

  // If
  csLog.ver = self.csLogDummyValues[kMSCSVer];

  // Then
  XCTAssertFalse([csLog isValid]);

  // If
  csLog.name = self.csLogDummyValues[kMSCSName];

  // Then
  XCTAssertFalse([csLog isValid]);

  // If
  csLog.timestamp = self.csLogDummyValues[kMSCSTime];

  // Then
  XCTAssertTrue([csLog isValid]);

  // IF
  [MSModelTestsUtililty populateAbstractLogWithDummies:csLog];

  // Then
  XCTAssertTrue([csLog isValid]);
}

- (void)testCSLogIsEqual {

  // If
  MSCommonSchemaLog *anotherCommonSchemaLog = [MSCommonSchemaLog new];

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog = [self csLogWithDummyValues:self.csLogDummyValues];

  // Then
  XCTAssertEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.ver = @"2.0";

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.ver = self.csLogDummyValues[kMSCSVer];
  anotherCommonSchemaLog.name = @"Alpha SDK";

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.name = self.csLogDummyValues[kMSCSName];
  anotherCommonSchemaLog.timestamp = [NSDate date];

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.timestamp = self.csLogDummyValues[kMSCSTime];
  anotherCommonSchemaLog.popSample = 101;

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.popSample = [self.csLogDummyValues[kMSCSPopSample] doubleValue];
  anotherCommonSchemaLog.iKey = @"o:0bcff4a2-6377-11e8-adc0-fa7ae01bbebc";

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.iKey = self.csLogDummyValues[kMSCSIKey];
  anotherCommonSchemaLog.flags = 31415927;

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.flags = [self.csLogDummyValues[kMSCSFlags] longLongValue];
  anotherCommonSchemaLog.cV = @"HyCFaiQoBkyEp0L3.1.3";

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.cV = self.csLogDummyValues[kMSCSCV];
  anotherCommonSchemaLog.ext = OCMClassMock([MSCSExtensions class]);

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.ext = self.csLogDummyValues[kMSCSExt];
  anotherCommonSchemaLog.data = OCMClassMock([MSCSData class]);

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.data = self.csLogDummyValues[kMSCSData];
  anotherCommonSchemaLog.flags = -1;

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.flags = [self.csLogDummyValues[kMSCSFlags] longLongValue];

  // Then
  XCTAssertEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);
}

- (void)testOrderedDictionaryPerformance {
  NSMutableArray *logs = [NSMutableArray new];
  for (int i = 0; i < 10000; i++) {
    [logs addObject:self.commonSchemaLog];
  }
  MSLogContainer *logContainer = [MSLogContainer new];
  [logContainer setLogs:logs];
  [self measureBlock:^{
    [logContainer serializeLog];
  }];
}

#pragma mark - Helper

- (MSCSExtensions *)extWithDummyValues {
  MSCSExtensions *ext = [MSCSExtensions new];
  ext.userExt = [self userExtWithDummyValues];
  ext.locExt = [self locExtWithDummyValues];
  ext.osExt = [self osExtWithDummyValues];
  ext.appExt = [self appExtWithDummyValues];
  ext.protocolExt = [self protocolExtWithDummyValues];
  ext.netExt = [self netExtWithDummyValues];
  ext.sdkExt = [self sdkExtWithDummyValues];
  return ext;
}

- (MSUserExtension *)userExtWithDummyValues {
  MSUserExtension *userExt = [MSUserExtension new];
  userExt.localId = @"c:alice";
  userExt.locale = @"en-us";
  return userExt;
}

- (MSLocExtension *)locExtWithDummyValues {
  MSLocExtension *locExt = [MSLocExtension new];
  locExt.tz = @"-05:00";
  return locExt;
}

- (MSOSExtension *)osExtWithDummyValues {
  MSOSExtension *osExt = [MSOSExtension new];
  osExt.name = @"Android";
  osExt.ver = @"Android P";
  return osExt;
}

- (MSAppExtension *)appExtWithDummyValues {
  MSAppExtension *appExt = [MSAppExtension new];
  appExt.appId = @"com.mamamia.bundle.id";
  appExt.ver = @"1.0.0";
  appExt.locale = @"fr-ca";
  appExt.userId = @"c:alice";
  return appExt;
}

- (MSProtocolExtension *)protocolExtWithDummyValues {
  MSProtocolExtension *protocolExt = [MSProtocolExtension new];
  protocolExt.devMake = @"Samsung";
  protocolExt.devModel = @"Samsung Galaxy S8";
  return protocolExt;
}

- (MSNetExtension *)netExtWithDummyValues {
  MSNetExtension *netExt = [MSNetExtension new];
  netExt.provider = @"M-Telecom";
  return netExt;
}

- (MSSDKExtension *)sdkExtWithDummyValues {
  MSSDKExtension *sdkExt = [MSSDKExtension new];
  sdkExt.libVer = @"3.1.4";
  sdkExt.epoch = MS_UUID_STRING;
  sdkExt.seq = 1;
  sdkExt.installId = [NSUUID new];
  return sdkExt;
}

- (MSCSData *)dataWithDummyValues {
  MSCSData *data = [MSCSData new];
  data.properties = [[MSModelTestsUtililty unorderedDataDummies] copy];
  return data;
}

- (MSCommonSchemaLog *)csLogWithDummyValues:(NSDictionary *)dummyValues {
  MSCommonSchemaLog *csLog = [MSCommonSchemaLog new];

  /*
   * These are deliberately out of order to verify that they are reordered properly when serialized.
   * Correct order is ver, name, timestamp, (popSample), iKey, flags.
   */
  csLog.name = dummyValues[kMSCSName];
  csLog.timestamp = dummyValues[kMSCSTime];
  csLog.ver = dummyValues[kMSCSVer];
  csLog.iKey = dummyValues[kMSCSIKey];
  csLog.flags = [dummyValues[kMSCSFlags] longLongValue];
  csLog.ext = dummyValues[kMSCSExt];
  csLog.data = dummyValues[kMSCSData];
  [MSModelTestsUtililty populateAbstractLogWithDummies:csLog];
  return csLog;
}

@end
