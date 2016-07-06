/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALogContainer.h"

@implementation AVALogContainer

-(id)initWithBatchId:(NSString*)batchId {
  if (self = [super init]) {
    self.batchId = batchId;
  }
  return self;
}

/**
 * Indicates whether the property with the given name is optional.
 * If `propertyName` is optional, then return `YES`, otherwise return `NO`.
 * This method is used by `JSONModel`.
 */
+ (BOOL)propertyIsOptional:(NSString *)propertyName {

  NSArray *optionalProperties = @[];
  return [optionalProperties containsObject:propertyName];
}

- (NSString*)serializeLog {

  NSString* jsonString = nil;
  
  NSMutableArray* jsonArray = [NSMutableArray array];
  
  [self.logs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    [obj write:dic];
    
    // Add to JSON array
    [jsonArray addObject:dic];
  }];
  
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray options:0 error:&error];
  
  if (!jsonData) {
    NSLog(@"Got an error: %@", error);
  } else {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
  return jsonString;
}

@end