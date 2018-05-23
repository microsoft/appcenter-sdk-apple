#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The Net extension contains network properties.
 */
@interface MSNetExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The network provider.
 */
@property(nonatomic, copy) NSString *provider;

@end
