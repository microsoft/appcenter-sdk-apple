#import <Foundation/Foundation.h>
#import "MSIdentityAuthority.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIdentityConfig : NSObject

@property (nonatomic, copy) NSString *scope;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *redirectUri;
@property (nonatomic, copy) NSArray<MSIdentityAuthority*> *authorities;

@end

NS_ASSUME_NONNULL_END
