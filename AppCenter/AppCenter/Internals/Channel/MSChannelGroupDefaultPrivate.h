NS_ASSUME_NONNULL_BEGIN

@class MSHttpIngestion;
@protocol MSStorage;

@interface MSChannelGroupDefault ()

/**
 * Initializes a new `MSChannelGroupDefault` instance.
 *
 * @param ingestion An HTTP ingestion instance that is used to send batches of
 * log items to the backend.
 *
 * @return A new `MSChannelGroupDefault` instance.
 */
- (instancetype)initWithIngestion:(nullable MSHttpIngestion *)ingestion;

@end

NS_ASSUME_NONNULL_END
