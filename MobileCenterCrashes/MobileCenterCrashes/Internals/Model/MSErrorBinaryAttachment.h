#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * Binary attachment for error log.
 */
@interface MSErrorBinaryAttachment : NSObject

/**
 * The fileName for binary data.
 */
@property(nonatomic, copy, readonly, nullable) NSString *fileName;

/**
 * Binary data.
 */
@property(nonatomic, copy, readonly) NSData *data;

/**
 * Content type for binary data.
 */
@property(nonatomic, copy, readonly) NSString *contentType;

/**
 * Is equal to another error binary attachment
 *
 * @param attachment Error binary attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable MSErrorBinaryAttachment *)attachment;

/**
 * Create an MSErrorBinaryAttachment instance with a given filename and NSData object
 * @param fileName The filename the attachment should get. If nil will get an automatically generated filename
 * @param data The attachment data as NSData.
 * @param contentType The content type of your data as MIME type.
 *
 * @return An instance of MSErrorBinaryAttachment.
 */
- (instancetype)initWithFileName:(nullable NSString *)fileName
                          attachmentData:(NSData *)data
                             contentType:(NSString *)contentType;

@end

NS_ASSUME_NONNULL_END
