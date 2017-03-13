#import <Foundation/Foundation.h>

@class MSErrorBinaryAttachment;

/*
 * Attachment for error log.
 */
@interface MSErrorAttachment : NSObject

/**
 * Plain text attachment [optional].
 */
@property(nonatomic, copy) NSString *textAttachment;

/**
 * Binary attachment [optional].
 */
@property(nonatomic) MSErrorBinaryAttachment *binaryAttachment;

/**
 * Is equal to another error attachment
 *
 * @param attachment Error attachment
 *
 * @return Return YES if equal and NO if not equal
 */
- (BOOL)isEqual:(MSErrorAttachment *)attachment;

+ (MSErrorAttachment *)attachmentWithText:(NSString *)text;

+ (MSErrorAttachment *)attachmentWithBinaryData:(NSData *)data
                                                filename:(NSString *)filename
                                                mimeType:(NSString *)mimeType;

+ (MSErrorAttachment *)attachmentWithText:(NSString *)text
                                     andBinaryData:(NSData *)data
                                          filename:(NSString *)filename
                                          mimeType:(NSString *)mimeType;

@end
