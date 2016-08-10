/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface AVABinaryAttachment : NSObject <NSCoding>

/**
 The filename the attachment should get
 */
@property (nonatomic, readonly, strong) NSString *filename;

/**
 The attachment data as NSData object
 */
@property (nonatomic, readonly, strong) NSData *data;

/**
 The content type of your data as MIME type
 */
@property (nonatomic, readonly, strong) NSString *contentType;

/**
 Create an AVABinaryAttachment instance with a given filename and NSData object
 
 @param filename The filename the attachment should get. If nil will get a automatically generated filename
 @param data The attachment data as NSData. The instance will be ignore if this is set to nil!
 @param contentType The content type of your data as MIME type. If nil will be set to "application/octet-stream"
 
 @return An instance of AVABinaryAttachment.
 */
- (instancetype)initWithFilename:(NSString *)filename
            attachmentData:(NSData *)data
                     contentType:(NSString *)contentType;

@end
