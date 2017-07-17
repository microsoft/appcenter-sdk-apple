#import <Foundation/Foundation.h>

@class MSWrapperException;

/**
 * This class helps wrapper SDKs augment crash reports with additional data.
 */
@interface MSWrapperExceptionManager : NSObject

+ (id) sharedInstance;

// this method is for use by wrapper sdk
- (void) saveWrapperException:(MSWrapperException *)wrapperException;

- (void) deleteWrapperExceptionWithUUID:(NSString *)uuid;

- (void) deleteAllWrapperExceptions;

- (MSWrapperException *) loadWrapperExceptionWithUUID:(NSString *)uuid;

@end
