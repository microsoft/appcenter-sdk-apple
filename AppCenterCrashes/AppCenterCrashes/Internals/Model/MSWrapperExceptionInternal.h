#import "MSSerializableObject.h"
#import "MSWrapperException.h"

/**
 * MSWrapperException must be serializable, but only internally (so that MSSerializableObject does not need to be bound for wrapper SDKs)
 */
@interface MSWrapperException () <MSSerializableObject>
@end
