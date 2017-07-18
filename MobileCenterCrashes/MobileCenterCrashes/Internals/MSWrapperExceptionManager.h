#import <Foundation/Foundation.h>

@class MSWrapperException;

/**
 * This class helps wrapper SDKs augment crash reports with additional data.
 */
@interface MSWrapperExceptionManager : NSObject

+ (void) saveWrapperException:(MSWrapperException *)wrapperException;
+(MSWrapperException *) loadWrapperExceptionWithUUID:(NSString *)uuid;

@end
