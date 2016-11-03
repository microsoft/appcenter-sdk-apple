/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSLog.h"
#import <Foundation/Foundation.h>

@interface MSLogContainer : NSObject

/**
 * Unique batch Id.
 */
@property(nonatomic) NSString *batchId;

/**
 * The list of logs
 */
@property(nonatomic) NSArray<MSLog> *logs;

/**
 * Initializer
 *
 * batchID Unique batch Id
 * logs Array of logs
 */
- (id)initWithBatchId:(NSString *)batchId andLogs:(NSArray<MSLog> *)logs;

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
