/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */


#import "MSPushInstallationLog.h"

static NSString *const kMSTypePushInstallationType = @"push_installation";

static NSString *const kMSPushInstallationId = @"installation_id";
static NSString *const kMSPushChannel = @"push_channel";
static NSString *const kMSPushPlatform = @"platform";
static NSString *const kMSPushTags = @"tags";

@implementation MSPushInstallationLog

@synthesize type = _type;

- (instancetype)init {
  self = [super init];

  if (self) {
    _type = kMSTypePushInstallationType;
    _platform = @"apns";
  }
  return self;
}

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [super serializeToDictionary];

  if (self.installationId) {
    dict[kMSPushInstallationId] = self.installationId;
  }
  if (self.pushChannel) {
    dict[kMSPushChannel] = self.pushChannel;
  }

  if (self.platform) {
    dict[kMSPushPlatform] = self.platform;
  }

  if (self.tags) {
    dict[kMSPushTags] = self.tags;
  }

  return dict;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _type = [coder decodeObjectForKey:kMSTypePushInstallationType];
    _installationId = [coder decodeObjectForKey:kMSPushInstallationId];
    _pushChannel = [coder decodeObjectForKey:kMSPushChannel];
    _platform = [coder decodeObjectForKey:kMSPushPlatform];
    _tags = [coder decodeObjectForKey:kMSPushTags];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.type forKey:kMSTypePushInstallationType];
  [coder encodeObject:self.installationId forKey:kMSPushInstallationId];
  [coder encodeObject:self.pushChannel forKey:kMSPushChannel];
  [coder encodeObject:self.platform forKey:kMSPushPlatform];
  [coder encodeObject:self.tags forKey:kMSPushTags];
}

@end
