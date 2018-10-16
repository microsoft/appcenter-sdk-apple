#import <Foundation/Foundation.h>

#import "AppCenter+Internal.h"
#import "MSSerializableObject.h"

@class MSStackFrame;

@interface MSException : NSObject <MSSerializableObject>

/*
 * Exception type.
 */
@property(nonatomic, copy) NSString *type;

/*
 * Exception reason.
 */
@property(nonatomic, copy) NSString *message;

/*
 * Raw stack trace. Sent when the frames property is either missing or unreliable.
 */
@property(nonatomic, copy) NSString *stackTrace;

/*
 * Stack frames [optional].
 */
@property(nonatomic) NSArray<MSStackFrame *> *frames;

/*
 * Inner exceptions of this exception [optional].
 */
@property(nonatomic) NSArray<MSException *> *innerExceptions;

/*
 * Name of the wrapper SDK that emitted this exception.
 * Consists of the name of the SDK and the wrapper platform, e.g. "appcenter.xamarin", "hockeysdk.cordova".
 */
@property(nonatomic, copy) NSString *wrapperSdkName;

/**
 * Checks if the object's values are valid.
 *
 * @return YES, if the object is valid.
 */
- (BOOL)isValid;

@end
