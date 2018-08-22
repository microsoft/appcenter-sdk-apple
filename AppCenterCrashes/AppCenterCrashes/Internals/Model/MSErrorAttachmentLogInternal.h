#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSErrorAttachmentLog.h"

/**
 * Error attachment log.
 */
@interface MSErrorAttachmentLog ()

/**
 * Error attachment identifier.
 */
@property(nonatomic, copy) NSString *attachmentId;

/**
 * Error log identifier to attach this log to.
 */
@property(nonatomic, copy) NSString *errorId;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
