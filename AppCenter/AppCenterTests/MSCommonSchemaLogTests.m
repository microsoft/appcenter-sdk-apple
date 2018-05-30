#import "MSCommonSchemaLog.h"
#import "MSCSConstants.h"
#import "MSTestFrameworks.h"

@interface MSCommonSchemaLogTests : XCTestCase
@property(nonatomic) MSCommonSchemaLog *commonSchemaLog;
@property(nonatomic) NSDictionary *csLogDummyValues;
@end

@implementation MSCommonSchemaLogTests

- (void)setUp {
  [super setUp];
  self.csLogDummyValues = @{
    kMSCSVer : @"3.0",
    kMSCSName : @"1DS",
    kMSCSTime : @(2193385800000000), // July 12, 2014 T 15:23:00
    kMSCSPopSample : @(100),
    kMSCSIKey : @"60cd0b94-6060-11e8-9c2d-fa7ae01bbebc",
    kMSCSFlags : @(31415926),
    kMSCSCV : @"HyCFaiQoBkyEp0L3.1.2",
    kMSCSExt : [self extWithDummyValues],
    kMSCSData : [self dataWithDummyValues]
  };
  self.commonSchemaLog = [self csLogWithDummyValues:self.csLogDummyValues];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - MSCommonSchemaLog

- (void)testCSLogJSONSerializingToDictionary {

  // When
  NSMutableDictionary *dict = [self.commonSchemaLog serializeToDictionary];

  // Then
  XCTAssertNotNil(dict);
  XCTAssertEqualObjects(dict, self.csLogDummyValues);
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
  XCTAssertEqual(actualCSLog.time, [self.csLogDummyValues[kMSCSTime] longLongValue]);
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
  csLog.time = [self.csLogDummyValues[kMSCSTime] longLongValue];

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
  anotherCommonSchemaLog.time = 2193385800000001;

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.time = [self.csLogDummyValues[kMSCSTime] longLongValue];
  anotherCommonSchemaLog.popSample = 101;

  // Then
  XCTAssertNotEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);

  // If
  anotherCommonSchemaLog.popSample = [self.csLogDummyValues[kMSCSPopSample] doubleValue];
  anotherCommonSchemaLog.iKey = @"0bcff4a2-6377-11e8-adc0-fa7ae01bbebc";

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

  // Then
  XCTAssertEqualObjects(anotherCommonSchemaLog, self.commonSchemaLog);
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
  userExt.locale = @"en-us";
  return userExt;
}

- (MSLocExtension *)locExtWithDummyValues {
  MSLocExtension *locExt = [MSLocExtension new];
  locExt.timezone = @"-05:00";
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
  netExt.provider = @"AT&T";
  return netExt;
}

- (MSSDKExtension *)sdkExtWithDummyValues {
  MSSDKExtension *sdkExt = [MSSDKExtension new];
  sdkExt.libVer = @"3.1.4";
  sdkExt.epoch = @"1527284987";
  sdkExt.seq = 1;
  sdkExt.installId = @"41b61ab0-5fbc-11e8-9c2d-fa7ae01bbebc";
  return sdkExt;
}

- (MSCSData *)dataWithDummyValues {
  MSCSData *data = [MSCSData new];
  NSDictionary *partCProperties = @{ @"Jan" : @"1", @"feb" : @"2", @"Mar" : @"3" };
  NSMutableDictionary *properties = [NSMutableDictionary new];
  properties[kMSDataProperties] = partCProperties;
  data.properties = properties;
  return data;
}

- (MSCommonSchemaLog *)csLogWithDummyValues:(NSDictionary *)dummyValues {
  MSCommonSchemaLog *csLog = [MSCommonSchemaLog new];
  csLog.ver = dummyValues[kMSCSVer];
  csLog.name = dummyValues[kMSCSName];
  csLog.time = [dummyValues[kMSCSTime] longLongValue];
  csLog.popSample = [dummyValues[kMSCSPopSample] doubleValue];
  csLog.iKey = dummyValues[kMSCSIKey];
  csLog.flags = [dummyValues[kMSCSFlags] longLongValue];
  csLog.cV = dummyValues[kMSCSCV];
  csLog.ext = dummyValues[kMSCSExt];
  csLog.data = dummyValues[kMSCSData];
  return csLog;
}

@end
