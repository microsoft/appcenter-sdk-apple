/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@protocol AVALog


@property(nonatomic) NSString* type;

/**
 * Corresponds to the number of milliseconds elapsed between the time the request is sent and the time the log is emitted.
 */
@property(nonatomic) NSNumber* toffset;

/**
 * A session identifier is used to correlate logs together. A session is an abstract concept in the API and 
 * is not necessarily an analytics session, it can be used to only track crashes.
 */
@property(nonatomic) NSUUID* sid;

- (void)read:(NSDictionary*)obj;
- (void)write:(NSMutableDictionary*)dic;
- (BOOL)isValid;

@end
