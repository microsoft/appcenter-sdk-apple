/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface AVASessionHistoryInfo : NSObject <NSCoding>

/**
 *  Session Id.
 */
@property (nonatomic) NSString *sessionId;

/**
 *  Time offset.
 */
@property(nonatomic) NSNumber *toffset;

@end
