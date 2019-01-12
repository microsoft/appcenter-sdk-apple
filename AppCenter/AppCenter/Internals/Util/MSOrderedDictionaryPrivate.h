#import "MSOrderedDictionary.h"

@interface MSOrderedDictionary ()

/**
 * An array containing the keys that are used to maintain the order.
 */
@property(nonatomic) NSMutableArray *order;

/**
 * The backing store for our ordered dictionary.
 */
@property(nonatomic) NSMutableDictionary *dictionary;

@end
