#import "MSCosmosDb.h"
#import "AppCenter+Internal.h"
#import "MSCosmosDbIngestion.h"
#import "MSDataStorageInternal.h"
#import "MSTokenResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Document DB base endpoint.
 */
static NSString *const kMSDocumentDbEndpoint = @"https://%@.documents.azure.com";

/**
 * Document DB database URL format.
 */
static NSString *const kMSDocumentDbDatabaseUrlFormat = @ "dbs/%@";

/**
 * Document DB collection URL format.
 */
static NSString *const kMSDocumentDbCollectionUrlFormat = @"colls/%@";

/**
 * Document DB document URL prefix.
 */
static NSString *const kMSDocumentDbDocumentUrlPrefix = @"docs";

/**
 * Document DB document URL format.
 */
static NSString *const kMSDocumentDbDocumentUrlFormat = @"docs/%@";

/**
 * Document DB document partition key format.
 */
static NSString *const kMSHeaderDocumentDbPartitionKeyFormat = @"[\"%@\"]";

/**
 * Document DB authorization header format
 * TODO : Change the "type" to be "resource" instead of "master"
 */
static NSString *const kMSDocumentDbAuthorizationHeaderFormat = @"type=master&ver=1.0&sig=%@";

/**
 * Url character set to skip(utf8 encoding).
 */
static NSString *const kMSUrlCharactersToEscape = @"!*'();:@&=+$,/?%#[]";

/**
 * RFC1123 locale.
 */
static NSString *const kMSRfc1123Locale = @"en_US";

/**
 * RFC1123 timezone.
 */
static NSString *const kMSRfc1123Timezone = @"GMT";

/**
 * RFC1123 format.
 */
static NSString *const kMSRfc1123Format = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";

/**
 * Headers.
 */
static NSString *const kMSHeaderDocumentDbPartitionKey = @"x-ms-documentdb-partitionkey";
static NSString *const kMSHeaderMsVesionValue = @"2018-06-18";
static NSString *const kMSHeaderMsVesion = @"x-ms-version";
static NSString *const kMSHeaderMsDate = @"x-ms-date";

@implementation MSCosmosDb : NSObject

+ (NSString *)encodeUrl:(NSString *)string {
  NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:kMSUrlCharactersToEscape] invertedSet];
  return (NSString *)[string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

+ (NSString *)rfc1123String:(NSDate *)date {
  static NSDateFormatter *df = nil;
  if (!df) {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
      df = [[NSDateFormatter alloc] init];
      df.locale = [[NSLocale alloc] initWithLocaleIdentifier:kMSRfc1123Locale];
      df.timeZone = [NSTimeZone timeZoneWithAbbreviation:kMSRfc1123Timezone];
      df.dateFormat = kMSRfc1123Format;
    });
  }
  return [df stringFromDate:date];
}

+ (NSDictionary *)defaultHeaderWithPartition:(NSString *)partition dbToken:(NSString *)dbToken {
  return @{
    kMSHeaderDocumentDbPartitionKey : [NSString stringWithFormat:kMSHeaderDocumentDbPartitionKeyFormat, partition],
    kMSHeaderMsVesion : kMSHeaderMsVesionValue,
    kMSHeaderMsDate : [MSCosmosDb rfc1123String:[NSDate date]],
    kMSHeaderContentTypeKey : kMSAppCenterContentType,
    kMSAuthorizationHeaderKey : [MSCosmosDb encodeUrl:dbToken]
  };
}

+ (NSString *)documentDbEndpointWithDbAccount:(NSString *)dbAccount documentResourceId:(NSString *)documentResourceId {
  NSString *documentEndpoint = [NSString stringWithFormat:kMSDocumentDbEndpoint, dbAccount];
  return [NSString stringWithFormat:@"%@/%@", documentEndpoint, documentResourceId];
}

+ (NSString *)documentBaseUrlWithDatabaseName:(NSString *)databaseName
                               collectionName:(NSString *)collectionName
                                   documentId:(NSString *)documentId {
  NSString *dbUrlSuffix = [NSString stringWithFormat:kMSDocumentDbDatabaseUrlSuffix, databaseName];
  NSString *dbCollectionUrlSuffix = [NSString stringWithFormat:kMSDocumentDbCollectionUrlSuffix, collectionName];
  NSString *dbDocumentId = documentId ? [NSString stringWithFormat:@"/%@", documentId] : @"";
  return [NSString stringWithFormat:@"%@/%@/%@%@", dbUrlSuffix, dbCollectionUrlSuffix, kMSDocumentDbDocumentUrlPrefix, dbDocumentId];
}

+ (NSString *)documentUrlWithTokenResult:(MSTokenResult *)tokenResult documentId:(NSString *)documentId {
  NSString *documentResourceIdPrefix = [MSCosmosDb documentBaseUrlWithDatabaseName:tokenResult.dbName
                                                                    collectionName:tokenResult.dbCollectionName
                                                                        documentId:documentId];
  return [MSCosmosDb documentDbEndpointWithDbAccount:tokenResult.dbAccount documentResourceId:documentResourceIdPrefix];
}

+ (void)cosmosDbAsync:(MSCosmosDbIngestion *)httpIngestion
          tokenResult:(MSTokenResult *)tokenResult
           documentId:(NSString *)documentId
             httpVerb:(NSString *)httpVerb
                 body:(NSString *)body
    completionHandler:(MSCosmosDbCompletionHandler)completion {

  // Configure http client.
  httpIngestion.httpVerb = httpVerb;
  httpIngestion.httpHeaders = [MSCosmosDb defaultHeaderWithPartition:tokenResult.partition dbToken:tokenResult.token];
  httpIngestion.sendURL = (NSURL *)[NSURL URLWithString:[MSCosmosDb documentUrlWithTokenResult:tokenResult documentId:documentId]];

  // Payload.
  NSData *payloadData = [body dataUsingEncoding:NSUTF8StringEncoding];
  [httpIngestion sendAsync:payloadData
         completionHandler:^(NSString *callId, NSHTTPURLResponse *response, NSData *data, NSError *error) {
           MSLogVerbose([MSDataStorage logTag], @"Cosmodb HttpClient callback, request Id %@ with status code: %lu", callId,
                        (unsigned long)response.statusCode);
           if (error) {
             MSLogError([MSDataStorage logTag], @"Cosmodb HttpClient callback, request Id %@ with error: %@", callId, [error description]);
           }

           // Completion handler.
           completion(data, error);
         }];
}

@end

NS_ASSUME_NONNULL_END
