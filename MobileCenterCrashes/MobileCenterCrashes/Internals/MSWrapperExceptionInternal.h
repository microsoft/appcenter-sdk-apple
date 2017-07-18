#import "MSSerializableObject.h"
#import "MSWrapperException.h"

/**
 * MSWrapperException must be serializable, but only internally.
 */
@interface MSWrapperException () <MSSerializableObject>
@end
