#import <Foundation/Foundation.h>
#import "MSAnalyticsTenant.h"

@interface MSAnalyticsTenant ()

/**
 * The tenant id corresponding to this tenant.
 */
@property(nonatomic) NSString *tenantId;

- (instancetype)initWithTenantId:(NSString *)tenantId;

@end
