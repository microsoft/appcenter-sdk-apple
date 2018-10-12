#import <Foundation/Foundation.h>

#import "MSAbstractErrorLog.h"

@class MSException;

/**
 * Handled Error log for managed platforms (such as Xamarin, Unity, Android Dalvik/ART).
 */
@interface MSHandledErrorLog : MSLogWithProperties

/**
 * Unique identifier for this error.
 */
@property(nonatomic, copy) NSString *errorId;

/**
 * The exception.
 */
@property(nonatomic) MSException *exception;

@end
