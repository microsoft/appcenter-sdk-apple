#import <Foundation/Foundation.h>
#import "MSAbstractDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDocumentUtils : NSObject

/**
 * Create document payload.
 *
 * @param documentId Document Id.
 * @param partition CosmosDb partition.
 * @param document Document in dictionary format.
 *
 * @return Dictionary of document payload.
 */
+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document;

/**
 * Validate serialization/deserialization of a doucment.
 *
 * @param document Serializable document.
 * @param error Serialization error(output).
 */
+ (void)validateSerializationWithDocument:(MSAbstractDocument *)document error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
