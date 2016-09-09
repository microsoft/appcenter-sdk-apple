/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMAbstractLog.h"
#import "SNMLogUtils.h"
#import "SNMLogger.h"
#import "SNMDevice.h"

static NSString *const kSNMSID = @"sid";
static NSString *const kSNMToffset = @"toffset";
static NSString *const kSNMDevice = @"device";
NSString *const kSNMType = @"type";

@implementation SNMAbstractLog

@synthesize type = _type;
@synthesize toffset = _toffset;
@synthesize sid = _sid;
@synthesize device = _device;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kSNMType] = self.type;
  }
  if (self.toffset) {

    // Set the toffset relative to current time. The toffset need to be up to date.
    NSInteger now = [[NSDate date] timeIntervalSince1970];
    NSInteger relativeTime = now - [self.toffset integerValue];
    dict[kSNMToffset] = @(relativeTime);
  }
  if (self.sid) {
    dict[kSNMSID] = self.sid;
  }
  if (self.device) {
    dict[kSNMDevice] = [self.device serializeToDictionary];
  }
  return dict;
}

- (BOOL)isValid {
  BOOL isValid = YES;

  // Is valid (session id can be nil).
  if (!self.type || !self.toffset || !self.device)
    isValid = NO;
  return isValid;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _toffset = [coder decodeObjectForKey:kSNMToffset];
    _sid = [coder decodeObjectForKey:kSNMSID];
    _device = [coder decodeObjectForKey:kSNMDevice];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.toffset forKey:kSNMToffset];
  [coder encodeObject:self.sid forKey:kSNMSID];
  [coder encodeObject:self.device forKey:kSNMDevice];
}

@end
