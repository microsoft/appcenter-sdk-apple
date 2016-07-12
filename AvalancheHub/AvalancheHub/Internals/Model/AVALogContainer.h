/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALog.h"
#import <Foundation/Foundation.h>

@interface AVALogContainer : NSObject

/**
 * Unique batch Id.
 */
@property(nonatomic) NSString *batchId;

/**
 * The list of logs
 */
@property(nonatomic) NSArray<AVALog> *logs;

/**
 * Initializer
 *
 * batchID Unique batch Id
 * logs Array of logs
 */
- (id)initWithBatchId:(NSString *)batchId andLogs:(NSArray<AVALog>*)logs;

/**
 * Serialize logs into a JSON string
 */
- (NSString *)serializeLog;

/**
 * Is valid container
 */
- (BOOL)isValid;

/**
 * Indicates whether the property with the given name is optional.
 * If `propertyName` is optional, then return `YES`, otherwise return `NO`.
 * This method is used by `JSONModel`.
 */
+ (BOOL)propertyIsOptional:(NSString *)propertyName;

@end
