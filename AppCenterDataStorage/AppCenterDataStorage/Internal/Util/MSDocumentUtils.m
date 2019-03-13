#import "MSDocumentUtils.h"
#import "MSDataStorageConstants.h"

@implementation MSDocumentUtils

+ (NSDictionary *)documentPayloadWithDocumentId:(NSString *)documentId partition:(NSString *)partition document:(NSDictionary *)document {
  return @{kMSDocument : document, kMSPartitionKey : partition, kMSIdKey : documentId};
}

@end
