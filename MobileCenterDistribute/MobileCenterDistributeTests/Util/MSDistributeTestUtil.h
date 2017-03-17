#import <Foundation/Foundation.h>

@interface MSDistributeTestUtil : NSObject

/**
 * Mobile Center mock.
 */
@property(class, nonatomic) id mobileCenterMock;

/**
 * Mobile Center util mock.
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
