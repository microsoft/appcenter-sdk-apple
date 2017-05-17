#import <Foundation/Foundation.h>

/*
 * Binary attachment for error log.
 */
@interface MSErrorBinaryAttachment : NSObject

/**
 * The fileName for binary data.
 */
@property(nonatomic, copy, readonly) NSString *fileName;

/**
 * Binary data.
 */
@property(nonatomic, copy, readonly) NSData *data;

/**
 * Content type for binary data.
 */
@property(nonatomic, copy, readonly) NSString *contentType;

/**
 * Checks if the values are valid.
 *
 * return YES if it is valid, otherwise NO.
 */
- (BOOL)isValid;

/**
 * Is equal to another error binary attachment
 *
 * @param object Error binary attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(id)object;

/**
 * Create an MSErrorBinaryAttachment instance with a given filename and NSData object
 * @param fileName The filename the attachment should get. If nil will get an automatically generated filename
 * @param data The attachment data as NSData.
 * @param contentType The content type of your data as MIME type.
 *
 * @return An instance of MSErrorBinaryAttachment.
 */
- (instancetype)initWithFileName:(NSString *)fileName
                          attachmentData:(NSData *)data
                             contentType:(NSString *)contentType;

@end
