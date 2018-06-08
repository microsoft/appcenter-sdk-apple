#import <Foundation/Foundation.h>

#import "MSEncrypter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSEncrypter ()

- (instancetype)initWitKeyTag:(NSString *)keyTag;

+ (void)deleteKeyWithTag:(NSString *)keyTag;

@end

NS_ASSUME_NONNULL_END
