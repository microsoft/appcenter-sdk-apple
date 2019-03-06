#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

static NSString *const kMSUserLocalId = @"localId";
static NSString *const kMSUserLocale = @"locale";

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
