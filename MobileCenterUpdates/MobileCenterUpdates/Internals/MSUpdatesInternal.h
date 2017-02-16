#import <Foundation/Foundation.h>
#import "MSSender.h"
#import "MSServiceInternal.h"
#import "MSUpdates.h"

@interface MSUpdates ()

@property(nonatomic, copy) NSString *apiUrl;

@property(nonatomic, copy) NSString *installUrl;

/**
 * A sender instance that is used to send update request to the backend.
 */
@property(nonatomic) id<MSSender> sender;

-(NSString *)apiUrl;
-(NSString *)installUrl;

@end
