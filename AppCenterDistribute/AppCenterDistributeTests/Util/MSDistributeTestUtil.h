#import <Foundation/Foundation.h>

@interface MSDistributeTestUtil : NSObject

/**
 * App Center mock.
 */
@property(class, nonatomic) id appCenterMock;

/**
 * App Center util mock.
 */
@property(class, nonatomic) id utilMock;

/**
 * Mock the conditions to allow updates.
 */
+ (void)mockUpdatesAllowedConditions;

/**
 * Unmock the conditions to allow updates.
 */
+ (void)unMockUpdatesAllowedConditions;

@end
