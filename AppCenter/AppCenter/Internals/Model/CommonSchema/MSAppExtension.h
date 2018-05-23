#import <Foundation/Foundation.h>
#import "MSSerializableObject.h"
#import "MSModel.h"

/**
 * The App extension contains data specified by the application.
 */
@interface MSAppExtension : NSObject <MSSerializableObject, MSModel>

/**
 * The application's bundle identifier.
 */
@property(nonatomic, copy) NSString *appId;

/**
 * The application's version.
 */
@property(nonatomic, copy) NSString *ver;

/**
 * The application's locale.
 */
@property(nonatomic, copy) NSString *locale;

@end
