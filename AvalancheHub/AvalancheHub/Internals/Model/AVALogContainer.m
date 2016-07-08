/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogContainer.h"

@implementation AVALogContainer

- (id)initWithBatchId:(NSString *)batchId {
  if (self = [super init]) {
    self.batchId = batchId;
  }
  return self;
}

- (NSString *)serializeLog {

  NSString *jsonString = nil;

  NSMutableArray *jsonArray = [NSMutableArray array];

  [self.logs enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx,
                                          BOOL *_Nonnull stop) {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [obj write:dic];

    // Add to JSON array
    [jsonArray addObject:dic];
  }];

  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:jsonArray options:0 error:&error];

  if (!jsonData) {
    NSLog(@"Got an error: %@", error);
  } else {
    jsonString =
        [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return jsonString;
}

- (BOOL)isValid {

  // Check for empty container
  if ([self.logs count] == 0 )
    return NO;
  
  __block BOOL isValid = YES;
  [self.logs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (![obj isValid]) {
      stop = YES;
      isValid = NO;
      return;
    }
  }];
  return isValid;
}
@end