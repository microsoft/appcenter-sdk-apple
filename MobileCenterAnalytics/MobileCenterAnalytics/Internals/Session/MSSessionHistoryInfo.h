/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

@import Foundation;

@interface MSSessionHistoryInfo : NSObject <NSCoding>

/**
 *  Session Id.
 */
@property(nonatomic, copy) NSString *sessionId;

/**
 *  Time offset.
 */
@property(nonatomic) NSNumber *toffset;

@end
