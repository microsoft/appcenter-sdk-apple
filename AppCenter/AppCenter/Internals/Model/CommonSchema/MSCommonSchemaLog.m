#import "MSCommonSchemaLog.h"
#import "MSCSData.h"
#import "MSCSExtensions.h"
#import "MSCSModelConstants.h"
#import "MSModel.h"
#import "MSOrderedDictionary.h"
#import "MSUtility+Date.h"

@implementation MSCommonSchemaLog

#pragma mark - MSSerializableObject

- (NSMutableDictionary *)serializeToDictionary {

  // ORDER MATTERS: Make sure ver, name, timestamp, popSample, iKey and flags appear first in part A.
  // No call to super here, it already contains everything needed for CS JSON serialization.
  NSMutableDictionary *dict = [MSOrderedDictionary new];
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

  // TODO: Not supporting popSample and cV today. When added, popSample needs to be ordered between timestamp and iKey.
  if (self.iKey) {
    dict[kMSCSIKey] = self.iKey;
  }
  if (self.flags) {
    dict[kMSCSFlags] = @(self.flags);
  }
  if (self.ext) {
    dict[kMSCSExt] = [self.ext serializeToDictionary];
  }
  if (self.data) {
    dict[kMSCSData] = [self.data serializeToDictionary];
  }
  return dict;
}

#pragma mark - MSModel

- (BOOL)isValid {

  // Do not call [super isValid] here as CS logs don't require the same validation as AC logs except for timestamp.
  return super.timestamp && self.ver && self.name;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (![(NSObject *)object isKindOfClass:[MSCommonSchemaLog class]] || ![super isEqual:object]) {
    return NO;
  }

  MSCommonSchemaLog *csLog = (MSCommonSchemaLog *)object;
  return ((!self.ver && !csLog.ver) || [self.ver isEqualToString:csLog.ver]) &&
         ((!self.name && !csLog.name) || [self.name isEqualToString:csLog.name]) && self.popSample == csLog.popSample &&
         ((!self.iKey && !csLog.iKey) || [self.iKey isEqualToString:csLog.iKey]) && self.flags == csLog.flags &&
         ((!self.cV && !csLog.cV) || [self.cV isEqualToString:csLog.cV]) && ((!self.ext && !csLog.ext) || [self.ext isEqual:csLog.ext]) &&
         ((!self.data && !csLog.data) || [self.data isEqual:csLog.data]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  if ((self = [super initWithCoder:coder])) {
    _ver = [coder decodeObjectForKey:kMSCSVer];
    _name = [coder decodeObjectForKey:kMSCSName];
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
  [coder encodeDouble:self.popSample forKey:kMSCSPopSample];
  [coder encodeObject:self.iKey forKey:kMSCSIKey];
  [coder encodeInt64:self.flags forKey:kMSCSFlags];
  [coder encodeObject:self.cV forKey:kMSCSCV];
  [coder encodeObject:self.ext forKey:kMSCSExt];
  [coder encodeObject:self.data forKey:kMSCSData];
}

@end
