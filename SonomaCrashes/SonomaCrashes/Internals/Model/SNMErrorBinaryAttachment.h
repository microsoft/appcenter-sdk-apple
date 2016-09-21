/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "SonomaCore+Internal.h"

/*
 * Binary attachment for error log.
 */
@interface SNMErrorBinaryAttachment : NSObject <SNMSerializableObject>


/**
 * The fileName for binary data.
 */
@property(nonatomic, readonly, nonnull) NSString *fileName;

/**
 * Binary data.
 */
@property(nonatomic, readonly, nonnull) NSData *data;

/**
 * Content type for binary data.
 */
@property(nonatomic, readonly, nonnull) NSString *contentType;

/**
 * Is equal to another error binary attachment
 *
 * @param attachment Error binary attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable SNMErrorBinaryAttachment *)attachment;

/**
 * Create an SNMErrorBinaryAttachment instance with a given filename and NSData object
 * @param fileName The filename the attachment should get. If nil will get an automatically generated filename
 * @param data The attachment data as NSData. The instance will be ignore if this is set to nil!
 * @param contentType The content type of your data as MIME type. If nil will be set to "application/octet-stream"
 *
 * @return An instance of SNMErrorBinaryAttachment.
 */
- (nonnull instancetype)initWithFileName:(nonnull NSString *)fileName attachmentData:(nonnull NSData *)data contentType:(nullable NSString *)contentType;

@end
