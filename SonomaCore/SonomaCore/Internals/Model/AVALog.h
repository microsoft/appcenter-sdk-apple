/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import <Foundation/Foundation.h>

@class AVADevice;

@protocol AVALog

/**
 * Log type.
 */
@property(nonatomic) NSString *type;

/**
 * Corresponds to the number of milliseconds elapsed between the time the
 * request is sent and the time the log is emitted.
 */
@property(nonatomic) NSNumber *toffset;

/**
 * A session identifier is used to correlate logs together. A session is an
 * abstract concept in the API and
 * is not necessarily an analytics session, it can be used to only track
 * crashes.
 */
@property(nonatomic) NSString *sid;

/**
 * Device properties associated to this log.
 */
@property(nonatomic) AVADevice *device;

/**
 * Checks if the object's values are valid.
 *
 * return YES, if the object is valid
 */
- (BOOL)isValid;

@end
