/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class SNMErrorBinaryAttachment;

/*
 * Attachment for error log.
 */
@interface SNMErrorAttachment : NSObject

/**
 * Plain text attachment [optional].
 */
@property(nonatomic, nullable) NSString *textAttachment;

/**
 * Binary attachment [optional].
 */
@property(nonatomic, nullable) SNMErrorBinaryAttachment *binaryAttachment;

/**
 * Is equal to another error attachment
 *
 * @param attachment Error attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable SNMErrorAttachment *)attachment;

+ (nonnull SNMErrorAttachment *)attachmentWithText:(nonnull NSString *)text;

+ (nonnull SNMErrorAttachment *)attachmentWithBinaryData:(nonnull NSData *)data
                                                filename:(nullable NSString *)filename
                                                mimeType:(nonnull NSString *)mimeType;

+ (nonnull SNMErrorAttachment *)attachmentWithText:(nonnull NSString *)text
                                     andBinaryData:(nonnull NSData *)data
                                          filename:(nullable NSString *)filename
                                          mimeType:(nonnull NSString *)mimeType;

@end
