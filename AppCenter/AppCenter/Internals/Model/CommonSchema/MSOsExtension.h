#import <Foundation/Foundation.h>

@interface MSOsExtension : NSObject

/**
 * The OS name.
 */
@property(nonatomic, copy) NSString *name;

/**
 * The OS version.
 */
@property(nonatomic, copy) NSString *ver;

@end
