/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSAbstractLog.h"
#import "MSLogger.h"
#import "MSDevice.h"
#import "MSDevicePrivate.h"

static NSString *const kMSSid = @"sid";
static NSString *const kMSToffset = @"toffset";
static NSString *const kMSDevice = @"device";
NSString *const kMSType = @"type";

@implementation MSAbstractLog

@synthesize type = _type;
@synthesize toffset = _toffset;
@synthesize sid = _sid;
@synthesize device = _device;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (self.type) {
    dict[kMSType] = self.type;
  }
  if (self.toffset) {

    // Set the toffset relative to current time. The toffset needs to be up to date.    
    NSInteger now = ([[NSDate date] timeIntervalSince1970] * 1000);
    NSInteger relativeTime = now - [self.toffset integerValue];
    dict[kMSToffset] = @(relativeTime);
  }
  if (self.sid) {
    dict[kMSSid] = self.sid;
  }
  if (self.device) {
    dict[kMSDevice] = [self.device serializeToDictionary];
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
    _toffset = [coder decodeObjectForKey:kMSToffset];
    _sid = [coder decodeObjectForKey:kMSSid];
    _device = [coder decodeObjectForKey:kMSDevice];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.toffset forKey:kMSToffset];
  [coder encodeObject:self.sid forKey:kMSSid];
  [coder encodeObject:self.device forKey:kMSDevice];
}

@end
