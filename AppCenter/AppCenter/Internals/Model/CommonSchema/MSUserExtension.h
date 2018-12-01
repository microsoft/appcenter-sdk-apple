#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * The “user” extension tracks common user elements that are not available in the core envelope.
 */
@interface MSUserExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Local Id.
 */
@property(nonatomic, copy) NSString *localId;

/**
 * User's locale.
 */
@property(nonatomic, copy) NSString *locale;

@end
