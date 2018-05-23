#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The “user” extension tracks common user elements that are not available in the core envelope.
 */
@interface MSUserExtension : NSObject <MSSerializableObject, MSModel>

/**
 * User's locale.
 */
@property(nonatomic, copy) NSString *locale;

@end
