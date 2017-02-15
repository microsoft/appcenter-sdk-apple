#import "MSUpdates.h"
#import "MSSender.h"
#import "MSServiceInternal.h"
#import <Foundation/Foundation.h>

@interface MSUpdates ()

@property(nonatomic, copy) NSString *loginUrl;

@property(nonatomic, copy) NSString *updateUrl;

/**
 * A sender instance that is used to send update request to the backend.
 */
@property(nonatomic) id<MSSender> sender;

- (NSString *)loginUrl;
- (NSString *)updateUrl;

@end
