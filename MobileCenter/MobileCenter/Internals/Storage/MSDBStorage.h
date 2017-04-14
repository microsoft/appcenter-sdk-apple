#import <Foundation/Foundation.h>
#import "MSStorage.h"

@interface MSDBStorage : NSObject <MSStorage>

/**
 * Return all logs with storageKey
 *
 * @return All founded logs
 */
- (NSMutableArray<MSLog>*) getLogsWith:(NSString*)storageKey;


/**
 * Delete all logs with storageKey
 */
- (void) deleteLogsWith:(NSString*)storageKey;

@end
