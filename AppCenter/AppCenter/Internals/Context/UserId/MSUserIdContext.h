#import <Foundation/Foundation.h>

#import "MSUserIdHistoryInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSUserIdContext : NSObject

/**
 * The current userId info.
 */
@property(nonatomic) MSUserIdHistoryInfo *currentUserIdInfo;

/**
 * The user Id history that contains user Id and timestamp as an item.
 */
@property(nonatomic) NSMutableArray<MSUserIdHistoryInfo *> *userIdHistory;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Set current user Id.
 *
 * @param userId The user Id.
 */
- (void)setUserId:(nullable NSString *)userId;

/**
 * Get current user Id.
 *
 * @return The current user Id.
 */
- (NSString *)userId;

/**
 * Get user Id at specific time.
 *
 * @param date The timestamp for the user Id.
 *
 * @return The user Id at the given time.
 */
- (nullable NSString *)userIdAt:(NSDate *)date;

/**
 * Clear all user Id history.
 */
- (void)clearUserIdHistory;

/**
 * Check if userId is valid for App Center.
 *
 * @param userId The user Id.
 *
 * @return YES if valid, NO otherwise.
 */
+ (BOOL)isUserIdValidForAppCenter:(nullable NSString *)userId;

/**
 * Check if userId is valid for One Collector.
 *
 * @param userId The user Id.
 *
 * @return YES if valid, NO otherwise.
 */
+ (BOOL)isUserIdValidForOneCollector:(nullable NSString *)userId;

/**
 * Add 'c:' prefix to userId if the userId has no prefix.
 *
 * @param userId userId.
 *
 * @return prefixed userId or null if the userId was null.
 */
+ (nullable NSString *)prefixedUserIdFromUserId:(nullable NSString *)userId;

@end

NS_ASSUME_NONNULL_END
