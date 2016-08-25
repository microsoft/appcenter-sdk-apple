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

+ (nonnull ErrorAttachment *)attachmentWithText:(nonnull NSString *)text;
+ (nonnull ErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data filename:(nonnull NSString *)filename mimeType:(nonnull NSString *)mimeType;
+ (nonnull ErrorAttachment *)attachmentWithText:(nonnull NSString *)text andBinaryData:(nonnull NSData *)data filename:(nonnull NSString *)filename mimeType:(nonnull NSString *)mimeType;
+ (nonnull ErrorAttachment *)attachmentWithURL:(nonnull NSURL *)file mimeType:(nullable NSString *)mimeType;

@end
