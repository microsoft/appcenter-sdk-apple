#import "MSCommonSchemaLog.h"
#import "MSCSConstants.h"
#import "MSModel.h"
#import "MSUtility+Date.h"

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
  
  // Timestamp already exists in the parent implementation but the serialized key is different.
  if (self.timestamp) {
    dict[kMSCSTime] = [MSUtility dateToISO8601:self.timestamp];
  }
  dict[kMSCSPopSample] = @(self.popSample);
  if (self.iKey) {
    dict[kMSCSIKey] = self.iKey;
  }
  dict[kMSCSFlags] = @(self.flags);
  if (self.cV) {
    dict[kMSCSCV] = self.cV;
  }
  if (self.ext) {
    dict[kMSCSExt] = self.ext;
  }
  if (self.data) {
    dict[kMSCSData] = self.data;
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {
  return [super isValid] && self.ver && self.name;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MSCommonSchemaLog class]] || ![super isEqual:object]) {
    return NO;
  }

  MSCommonSchemaLog *csLog = (MSCommonSchemaLog *)object;
  return ((!self.ver && !csLog.ver) || [self.ver isEqualToString:csLog.ver]) &&
         ((!self.name && !csLog.name) || [self.name isEqualToString:csLog.name]) &&
         self.popSample == csLog.popSample && ((!self.iKey && !csLog.iKey) || [self.iKey isEqualToString:csLog.iKey]) &&
         self.flags == csLog.flags && ((!self.cV && !csLog.cV) || [self.cV isEqualToString:csLog.cV]) &&
         ((!self.ext && !csLog.ext) || [self.ext isEqual:csLog.ext]) &&
         ((!self.data && !csLog.data) || [self.data isEqual:csLog.data]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super initWithCoder:coder])) {
    _ver = [coder decodeObjectForKey:kMSCSVer];
    _name = [coder decodeObjectForKey:kMSCSName];
    self.timestamp = [coder decodeObjectForKey:kMSCSTime];
    _popSample = [coder decodeDoubleForKey:kMSCSPopSample];
    _iKey = [coder decodeObjectForKey:kMSCSIKey];
    _flags = [coder decodeInt64ForKey:kMSCSFlags];
    _cV = [coder decodeObjectForKey:kMSCSCV];
    _ext = [coder decodeObjectForKey:kMSCSExt];
    _data = [coder decodeObjectForKey:kMSCSData];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.ver forKey:kMSCSVer];
  [coder encodeObject:self.name forKey:kMSCSName];
  [coder encodeObject:self.timestamp forKey:kMSCSTime];
  [coder encodeDouble:self.popSample forKey:kMSCSPopSample];
  [coder encodeObject:self.iKey forKey:kMSCSIKey];
  [coder encodeInt64:self.flags forKey:kMSCSFlags];
  [coder encodeObject:self.cV forKey:kMSCSCV];
  [coder encodeObject:self.ext forKey:kMSCSExt];
  [coder encodeObject:self.data forKey:kMSCSData];
}

@end
