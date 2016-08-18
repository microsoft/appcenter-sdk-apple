//
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class AVABinaryAttachment;

@interface AVAErrorAttachment : NSObject

/**
 * Text attachment, e.g. a user's mail address.
 */
@property(nonatomic) NSString *textAttachment;

/**
 * A binary attachment, can be anything, e.g. a db dump.
 */
@property(nonatomic, readwrite) AVABinaryAttachment *attachmentFile;

@end
