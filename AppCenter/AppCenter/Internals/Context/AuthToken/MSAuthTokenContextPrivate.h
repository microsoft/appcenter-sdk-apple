#import <Foundation/Foundation.h>

#import "MSAuthTokenContext.h"

@interface MSAuthTokenContext ()

/**
 * Authorization token cached value.
 */
@property(nullable, atomic, copy) NSString *authToken;

/**
 * The last value of user account id.
 */
@property(nullable, nonatomic, copy) NSString *homeAccountId;

/**
 * Collection of channel delegates.
 */
@property(nonatomic) NSHashTable<id<MSAuthTokenContextDelegate>> *delegates;

@end
