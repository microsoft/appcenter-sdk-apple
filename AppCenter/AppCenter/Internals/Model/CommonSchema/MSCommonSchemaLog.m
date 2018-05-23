#import "MSCommonSchemaLog.h"
#import "MSModel.h"

static NSString *const kMSCSVer = @"ver";
static NSString *const kMSCSName = @"name";
static NSString *const kMSCSTime = @"time";
static NSString *const kMSCSPopSample = @"popSample";
static NSString *const kMSCSIKey = @"iKey";
static NSString *const kMSCSFlags = @"flags";
static NSString *const kMSCSCV = @"cV";
static NSString *const kMSCSExtProtocol = @"extProtocol";
static NSString *const kMSCSExtUser = @"extUser";
static NSString *const kMSCSExtOS = @"extOs";
static NSString *const kMSCSExtApp = @"extApp";
static NSString *const kMSCSExtNet = @"extNet";
static NSString *const kMSCSExtSDK = @"extSdk";
static NSString *const kMSCSExtLoc = @"extLoc";
static NSString *const kMSCSData = @"data";

@implementation MSCommonSchemaLog

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  if (self.ver) {
    dict[kMSCSVer] = self.ver;
  }
  if (self.name) {
    dict[kMSCSName] = self.name;
  }
  dict[kMSCSTime] = @(self.time);
  dict[kMSCSPopSample] = @(self.popSample);
  if (self.iKey) {
    dict[kMSCSIKey] = self.iKey;
  }
  dict[kMSCSFlags] = @(self.flags);
  if (self.cV) {
    dict[kMSCSCV] = self.cV;
  }
  if (self.extProtocol) {
    dict[kMSCSExtProtocol] = self.extProtocol;
  }
  if (self.extUser) {
    dict[kMSCSExtUser] = self.extUser;
  }
  if (self.extOs) {
    dict[kMSCSExtOS] = self.extOs;
  }
  if (self.extApp) {
    dict[kMSCSExtApp] = self.extApp;
  }
  if (self.extNet) {
    dict[kMSCSExtNet] = self.extNet;
  }
  if (self.extSdk) {
    dict[kMSCSExtSDK] = self.extSdk;
  }
  if (self.extLoc) {
    dict[kMSCSExtLoc] = self.extLoc;
  }
  if (self.data) {
    dict[kMSCSData] = self.data;
  }

  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return self.ver && self.name && self.iKey && self.cV && [self.extProtocol isValid] && [self.extUser isValid] &&
         [self.extOs isValid] && [self.extApp isValid] && [self.extNet isValid] && [self.extSdk isValid] &&
         [self.extLoc isValid] && [self.data isValid];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSCommonSchemaLog class]]) {
    return NO;
  }

  MSCommonSchemaLog *csLog = (MSCommonSchemaLog *)object;
  return ((!self.ver && !csLog.ver) || [self.ver isEqualToString:csLog.ver]) &&
         ((!self.name && !csLog.name) || [self.name isEqualToString:csLog.name]) && self.time == csLog.time &&
         self.popSample == csLog.popSample && ((!self.iKey && !csLog.iKey) || [self.iKey isEqualToString:csLog.iKey]) &&
         self.flags == csLog.flags && ((!self.cV && !csLog.cV) || [self.cV isEqualToString:csLog.cV]) &&
         ((!self.extProtocol && !csLog.extProtocol) || [self.extProtocol isEqual:csLog.extProtocol]) &&
         ((!self.extUser && !csLog.extUser) || [self.extUser isEqual:csLog.extUser]) &&
         ((!self.extOs && !csLog.extOs) || [self.extOs isEqual:csLog.extOs]) &&
         ((!self.extApp && !csLog.extApp) || [self.extApp isEqual:csLog.extApp]) &&
         ((!self.extNet && !csLog.extNet) || [self.extNet isEqual:csLog.extNet]) &&
         ((!self.extSdk && !csLog.extSdk) || [self.extSdk isEqual:csLog.extSdk]) &&
         ((!self.extLoc && !csLog.extLoc) || [self.extLoc isEqual:csLog.extLoc]) &&
         ((!self.data && !csLog.data) || [self.data isEqual:csLog.data]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    _ver = [coder decodeObjectForKey:kMSCSVer];
    _name = [coder decodeObjectForKey:kMSCSName];
    _time = [coder decodeInt64ForKey:kMSCSTime];
    _popSample = [coder decodeDoubleForKey:kMSCSPopSample];
    _iKey = [coder decodeObjectForKey:kMSCSIKey];
    _flags = [coder decodeInt64ForKey:kMSCSFlags];
    _cV = [coder decodeObjectForKey:kMSCSCV];
    _extProtocol = [coder decodeObjectForKey:kMSCSExtProtocol];
    _extUser = [coder decodeObjectForKey:kMSCSExtUser];
    _extOs = [coder decodeObjectForKey:kMSCSExtOS];
    _extApp = [coder decodeObjectForKey:kMSCSExtApp];
    _extNet = [coder decodeObjectForKey:kMSCSExtNet];
    _extSdk = [coder decodeObjectForKey:kMSCSExtSDK];
    _extLoc = [coder decodeObjectForKey:kMSCSExtLoc];
    _data = [coder decodeObjectForKey:kMSCSData];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.ver forKey:kMSCSVer];
  [coder encodeObject:self.name forKey:kMSCSName];
  [coder encodeInt64:self.time forKey:kMSCSTime];
  [coder encodeDouble:self.popSample forKey:kMSCSPopSample];
  [coder encodeObject:self.iKey forKey:kMSCSIKey];
  [coder encodeInt64:self.flags forKey:kMSCSFlags];
  [coder encodeObject:self.cV forKey:kMSCSCV];
  [coder encodeObject:self.extProtocol forKey:kMSCSExtProtocol];
  [coder encodeObject:self.extUser forKey:kMSCSExtUser];
  [coder encodeObject:self.extOs forKey:kMSCSExtOS];
  [coder encodeObject:self.extApp forKey:kMSCSExtApp];
  [coder encodeObject:self.extNet forKey:kMSCSExtNet];
  [coder encodeObject:self.extSdk forKey:kMSCSExtSDK];
  [coder encodeObject:self.extLoc forKey:kMSCSExtLoc];
  [coder encodeObject:self.data forKey:kMSCSData];
}

@end
