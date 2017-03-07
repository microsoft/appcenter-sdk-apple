#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MSErrorBinaryAttachment;

/*
 * Attachment for error log.
 */
@interface MSErrorAttachment : NSObject

/**
 * Plain text attachment [optional].
 */
@property(nonatomic, copy, nullable) NSString *textAttachment;

/**
 * Binary attachment [optional].
 */
@property(nonatomic, nullable) MSErrorBinaryAttachment *binaryAttachment;

/**
 * Is equal to another error attachment
 *
 * @param attachment Error attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(nullable MSErrorAttachment *)attachment;

+ (nonnull MSErrorAttachment *)attachmentWithText:(NSString *)text;

+ (nonnull MSErrorAttachment *)attachmentWithBinaryData:(NSData *)data
                                                filename:(nullable NSString *)filename
                                                mimeType:(NSString *)mimeType;

+ (nonnull MSErrorAttachment *)attachmentWithText:(NSString *)text
                                     andBinaryData:(NSData *)data
                                          filename:(nullable NSString *)filename
                                          mimeType:(NSString *)mimeType;

@end

NS_ASSUME_NONNULL_END
