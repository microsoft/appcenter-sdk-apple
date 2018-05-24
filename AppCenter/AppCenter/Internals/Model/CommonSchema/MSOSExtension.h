#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The OS extension tracks common os elements that are not available in the core envelope.
 */
@interface MSOSExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The OS name.
 */
@property(nonatomic, copy) NSString *name;

/**
 * The OS version.
 */
@property(nonatomic, copy) NSString *ver;

@end
