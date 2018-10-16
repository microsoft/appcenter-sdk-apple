#import "MSOneCollectorChannelDelegate.h"

@class MSOneCollectorIngestion;

@protocol MSChannelUnitProtocol;
@protocol MSLog;

@class MSCSEpochAndSeq;

/**
 * Regex for Custom Schema log name validation.
 */
extern NSString *const kMSLogNameRegex;

@interface MSOneCollectorChannelDelegate ()

/**
 * Collection of channel unit protocols per group Id.
 */
@property(nonatomic) NSMutableDictionary<NSString *, id<MSChannelUnitProtocol>> *oneCollectorChannels;

/**
 * Http ingestion to send logs to One Collector endpoint.
 */
@property(nonatomic) MSOneCollectorIngestion *oneCollectorIngestion;

/**
 * Keep track of epoch and sequence per tenant token.
 */
@property(nonatomic) NSMutableDictionary<NSString *, MSCSEpochAndSeq *> *epochsAndSeqsByIKey;

/**
 * UUID created on first-time SDK initialization.
 */
@property(nonatomic) NSUUID *installId;

/**
 * Returns 'YES' if the log should be sent to one collector.
 */
- (BOOL)shouldSendLogToOneCollector:(id<MSLog>)log;

/**
 * Validate Common Schema 3.0 Log.
 *
 * @param log The Common Schema log.
 *
 * @return YES if Common Schema log is valid; NO otherwise.
 */
- (BOOL)validateLog:(MSCommonSchemaLog *)log;

/**
 * Validate Common Schema log name.
 *
 * @param name The log name.
 *
 * @return YES if name is valid, NO otherwise.
 */
- (BOOL)validateLogName:(NSString *)name;

@end
