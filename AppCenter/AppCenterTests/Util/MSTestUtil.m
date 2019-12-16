// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSTestUtil.h"
#import "MSDevice.h"
#import "MSLogContainer.h"
#import "MSMockLog.h"
#import "MSUtility+StringFormatting.h"

@implementation MSTestUtil

+ (MSLogContainer *)createLogContainerWithId:(NSString *)batchId device:(MSDevice *)device {
  MSMockLog *log1 = [[MSMockLog alloc] init];
  log1.sid = MS_UUID_STRING;
  log1.timestamp = [NSDate date];
  log1.device = device;

  MSMockLog *log2 = [[MSMockLog alloc] init];
  log2.sid = MS_UUID_STRING;
  log2.timestamp = [NSDate date];
  log2.device = device;

  MSLogContainer *logContainer = [[MSLogContainer alloc] initWithBatchId:batchId andLogs:(NSArray<id<MSLog>> *)@[ log1, log2 ]];
  return logContainer;
}

@end
