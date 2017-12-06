#import "MSKeychainUtil.h"

@interface MSKeychainUtil (DistributeMigration)

/**
 * Migrate Distribute data from past versions.
 */
+ (void)migrateDistributeData;

@end

