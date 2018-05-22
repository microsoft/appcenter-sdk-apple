#import <Foundation/Foundation.h>

@interface MSAppExtension : NSObject

@property(nonatomic, copy) NSString *appId;
@property(nonatomic, copy) NSString *ver;
@property(nonatomic, copy) NSString *locale;

@end
