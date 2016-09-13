//
/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "SonomaCore+Internal.h"

@class AVAErrorBinaryAttachment;

/*
 * Attachment for error log.
 */
@interface AVAErrorAttachment : NSObject <AVASerializableObject>

/**
 * Plain text attachment [optional].
 */
@property(nonatomic, nullable) NSString *textAttachment;

/**
 * Binary attachment [optional].
 */
@property(nonatomic, nullable) AVAErrorBinaryAttachment *binaryAttachment;

+ (nonnull AVAErrorAttachment *)attachmentWithText:(nonnull NSString *)text;

+ (nonnull AVAErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data filename:(nonnull NSString *)filename mimeType:(nonnull NSString *)mimeType;

+ (nonnull AVAErrorAttachment *)attachmentWithText:(nonnull NSString *)text andBinaryData:(nonnull NSData *)data filename:(nonnull NSString *)filename mimeType:(nonnull NSString *)mimeType;

+ (nonnull AVAErrorAttachment *)attachmentWithURL:(nonnull NSURL *)file mimeType:(nullable NSString *)mimeType;

@end
