/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAbstractLog.h"
#import "AVALogUtils.h"
#import "AVALogger.h"

static NSString *const kAVASID = @"sid";
static NSString *const kAVAToffset = @"toffset";
NSString *const kAVAType = @"type";

@implementation AVAAbstractLog

@synthesize type = _type;
@synthesize toffset = _toffset;
@synthesize sid = _sid;

- (NSMutableDictionary *)serializeToDictionary {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  
  if (self.type) {
    dict[kAVAType] = self.type;
  }
  if (self.toffset) {
    dict[kAVAToffset] = self.toffset;
  }
  if (self.sid) {
    dict[kAVASID] = self.sid;
  }
  return dict;
}

- (BOOL)isValid {
  BOOL isValid = YES;

  // Is valid
  isValid = (!self.type || !self.sid || !self.toffset);
  return isValid;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if(self) {
    _toffset = [coder decodeObjectForKey:kAVAToffset];
    _sid = [coder decodeObjectForKey:kAVASID];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.toffset forKey:kAVAToffset];
  [coder encodeObject:self.sid forKey:kAVASID];
}

@end
