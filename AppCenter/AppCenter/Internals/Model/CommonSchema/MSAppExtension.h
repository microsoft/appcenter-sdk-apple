#import <Foundation/Foundation.h>

@interface MSAppExtension : NSObject

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
