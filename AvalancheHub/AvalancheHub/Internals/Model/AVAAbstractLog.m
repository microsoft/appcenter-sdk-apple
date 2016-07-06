/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAAbstractLog.h"
#import "AVALogger.h"
#import "AVALogUtils.h"

static NSString* const kAVASID = @"sid";
static NSString* const kAVAToffset = @"toffset";
static NSString* const kAVAType = @"type";

@implementation AVAAbstractLog

@synthesize type;
@synthesize toffset;
@synthesize sid;

- (void)write:(NSMutableDictionary*)dic {
  dic[kAVAType] = self.type;
  dic[kAVAToffset] = self.toffset;
  dic[kAVASID] = [self.sid UUIDString];
}

- (void)read:(NSDictionary*)obj{
  if ([obj[kAVAType] isEqualToString:[self type]]) {
    
    AVALogError(@"ERROR: invalid object");
    return;
  }

  // Set properties
  self.toffset = obj[kAVAToffset];
  self.sid = obj[kAVASID];
}

- (BOOL)isValid {
  BOOL isValid = YES;
  
  // Is valid
  isValid =  (!self.type ||
              !self.sid ||
              !self.toffset);
  return isValid;
}

@end
