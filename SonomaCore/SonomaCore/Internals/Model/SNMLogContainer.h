/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "SNMLog.h"
#import <Foundation/Foundation.h>

@interface SNMLogContainer : NSObject

/**
 * Unique batch Id.
 */
@property(nonatomic) NSString *batchId;

/**
 * The list of logs
 */
@property(nonatomic) NSArray<SNMLog> *logs;

/**
 * Initializer
 *
 * batchID Unique batch Id
 * logs Array of logs
 */
- (id)initWithBatchId:(NSString *)batchId andLogs:(NSArray<SNMLog> *)logs;

/**
 * Serialize logs into a JSON string
 */
- (NSString *)serializeLog;

/**
 *  Serialize logs into a JSON string.
 *
 *  @param prettyPrint boolean indicates pretty printing.
 *
 *  @return serialized string.
 */
- (NSString *)serializeLogWithPrettyPrinting:(BOOL)prettyPrint;

/**
 * Is valid container
 */
- (BOOL)isValid;

@end
