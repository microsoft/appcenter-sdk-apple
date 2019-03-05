#import "MSPage.h"

@implementation MSPage

/**
 * Continuation token for retrieving the next page from CosmosDB.
 */
@synthesize continuationToken = _continuationToken;

/**
 * Error (or null).
 */
@synthesize error = _error;

/**
 * Array of documents in the current page (or null).
 */
@synthesize items = _items;

@end
