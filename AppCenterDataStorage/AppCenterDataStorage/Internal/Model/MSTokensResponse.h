#import <Foundation/Foundation.h>

@class MSTokenResult;

@interface MSTokensResponse : NSObject

@property(nonatomic, readonly) NSArray<MSTokenResult *> *tokens;

- (instancetype)initWithTokens:(NSArray<MSTokenResult *> *)tokens;

@end
