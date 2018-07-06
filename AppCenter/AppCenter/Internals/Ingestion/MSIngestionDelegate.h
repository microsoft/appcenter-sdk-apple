@protocol MSIngestionProtocol;

@protocol MSIngestionDelegate <NSObject>

@optional

/**
 * Triggered after the ingestion has suspended its state.
 *
 * @param ingestion Ingestion.
 */
- (void)ingestionDidSuspend:(id<MSIngestionProtocol>)ingestion;

/**
 * Triggered after the ingestion has resumed its state.
 *
 * @param ingestion Ingestion.
 */
- (void)ingestionDidResume:(id<MSIngestionProtocol>)ingestion;

/**
 * Triggered when ingestion receives a fatal error.
 *
 * @param ingestion Ingestion.
 */
- (void)ingestionDidReceiveFatalError:(id<MSIngestionProtocol>)ingestion;

@end
