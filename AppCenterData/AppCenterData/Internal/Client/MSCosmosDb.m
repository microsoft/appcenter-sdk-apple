// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSCosmosDb.h"
#import "AppCenter+Internal.h"
#import "MSConstants+Internal.h"
#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDocumentUtils.h"
#import "MSTokenResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Document DB base endpoint.
 */
static NSString *const kMSDocumentDbEndpoint = @"https://%@.documents.azure.com";

/**
 * Document DB collection URL suffix format.
 */
static NSString *const kMSDocumentDbCollectionUrlSuffix = @"colls/%@";

/**
 * Document DB document URL prefix.
 */
static NSString *const kMSDocumentDbDocumentUrlPrefix = @"docs";

/**
 * Document DB document URL suffix format.
 */
static NSString *const kMSDocumentDbDatabaseUrlSuffix = @"dbs/%@";

/**
 * Document DB document partition key format.
 */
static NSString *const kMSHeaderDocumentDbPartitionKeyFormat = @"[\"%@\"]";

/**
 * Document DB authorization header format
 */
static NSString *const kMSDocumentDbAuthorizationHeaderFormat = @"type=master&ver=1.0&sig=%@";

/**
 * Url character set to skip(utf8 encoding).
 */
static NSString *const kMSUrlCharactersToEscape = @"!*'();:@&=+$,/?%#[]\" ";

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

+ (NSDictionary *)defaultHeaderWithPartition:(NSString *)partition
                                     dbToken:(NSString *)dbToken
                           additionalHeaders:(NSDictionary *_Nullable)additionalHeaders {
  NSMutableDictionary *allHeaders = [NSMutableDictionary dictionaryWithDictionary:@{
    kMSHeaderDocumentDbPartitionKey : [NSString stringWithFormat:kMSHeaderDocumentDbPartitionKeyFormat, partition],
    kMSHeaderMsVesion : kMSHeaderMsVesionValue,
    kMSHeaderMsDate : [MSCosmosDb rfc1123String:[NSDate date]],
    kMSHeaderContentTypeKey : kMSAppCenterContentType,
    kMSAuthorizationHeaderKey : [MSCosmosDb encodeUrl:dbToken]
  }];

  // Add additional headers (if any).
  if (additionalHeaders) {
    [allHeaders addEntriesFromDictionary:(NSDictionary *)additionalHeaders];
  }
  return allHeaders;
}

+ (NSString *)documentDbEndpointWithDbAccount:(NSString *)dbAccount documentResourceId:(NSString *)documentResourceId {
  NSString *documentEndpoint = [NSString stringWithFormat:kMSDocumentDbEndpoint, dbAccount];
  return [NSString stringWithFormat:@"%@/%@", documentEndpoint, documentResourceId];
}

+ (NSString *)documentBaseUrlWithDatabaseName:(NSString *)databaseName
                               collectionName:(NSString *)collectionName
                                   documentId:(NSString *_Nullable)documentId {
  NSString *dbUrlSuffix = [NSString stringWithFormat:kMSDocumentDbDatabaseUrlSuffix, [MSCosmosDb encodeUrl:databaseName]];
  NSString *dbCollectionUrlSuffix = [NSString stringWithFormat:kMSDocumentDbCollectionUrlSuffix, [MSCosmosDb encodeUrl:collectionName]];
  NSString *dbDocumentId = documentId ? [NSString stringWithFormat:@"/%@", [MSCosmosDb encodeUrl:(NSString *)documentId]] : @"";
  return [NSString stringWithFormat:@"%@/%@/%@%@", dbUrlSuffix, dbCollectionUrlSuffix, kMSDocumentDbDocumentUrlPrefix, dbDocumentId];
}

+ (NSString *)documentUrlWithTokenResult:(MSTokenResult *)tokenResult documentId:(NSString *_Nullable)documentId {
  NSString *documentResourceIdPrefix = [MSCosmosDb documentBaseUrlWithDatabaseName:tokenResult.dbName
                                                                    collectionName:tokenResult.dbCollectionName
                                                                        documentId:documentId];
  return [MSCosmosDb documentDbEndpointWithDbAccount:tokenResult.dbAccount documentResourceId:documentResourceIdPrefix];
}

+ (void)performCosmosDbAsyncOperationWithHttpClient:(id<MSHttpClientProtocol>)httpClient
                                        tokenResult:(MSTokenResult *)tokenResult
                                         documentId:(NSString *_Nullable)documentId
                                         httpMethod:(NSString *)httpMethod
                                           document:(id<MSSerializableDocument> _Nullable)document
                                  additionalHeaders:(NSDictionary *_Nullable)additionalHeaders
                                  additionalUrlPath:(NSString *_Nullable)additionalUrlPath
                                  completionHandler:(MSHttpRequestCompletionHandler)completionHandler {
  NSData *body = nil;
  if (document) {

    // Check for document id.
    if (!documentId) {
      MSLogError([MSData logTag], @"Can't perform CosmodDb operation without document id.");
      NSError *error = [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                                  code:MSACDataErrorDocumentIdMissing
                                              userInfo:@{NSLocalizedDescriptionKey : kMSACDocumentCreationDesc}];
      completionHandler(nil, nil, error);
      return;
    }

    // Get the document as dictionary.
    NSError *serializationError;
    NSDictionary *dic = [MSDocumentUtils documentPayloadWithDocumentId:(NSString *)documentId
                                                             partition:tokenResult.partition
                                                              document:(NSDictionary *)[document serializeToDictionary]];
    if (![NSJSONSerialization isValidJSONObject:dic]) {
      serializationError =
          [[NSError alloc] initWithDomain:kMSACDataErrorDomain
                                     code:MSACDataErrorJSONSerializationFailed
                                 userInfo:@{NSLocalizedDescriptionKey : @"Document dictionary contains values that cannot be serialized."}];
      MSLogError([MSData logTag], @"Error serializing data: %@", [serializationError localizedDescription]);
      completionHandler(nil, nil, serializationError);
      return;
    }

    // Serialize document
    body = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&serializationError];
    if (!body || serializationError) {
      MSLogError([MSData logTag], @"Error serializing data: %@", [serializationError localizedDescription]);
      completionHandler(nil, nil, serializationError);
      return;
    }
  }

  // Create http request.
  NSDictionary *httpHeaders = [MSCosmosDb defaultHeaderWithPartition:tokenResult.partition
                                                             dbToken:tokenResult.token
                                                   additionalHeaders:additionalHeaders];
  NSURL *sendURL = (NSURL *)[NSURL URLWithString:[MSCosmosDb documentUrlWithTokenResult:tokenResult
                                                                             documentId:(NSString *)additionalUrlPath]];
  [httpClient sendAsync:sendURL method:httpMethod headers:httpHeaders data:body completionHandler:completionHandler];
}

+ (MSDataError *)cosmosDbErrorWithResponse:(NSHTTPURLResponse *_Nullable)response underlyingError:(NSError *_Nullable)error {

  // Prepare user info properties.
  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  userInfo[NSLocalizedDescriptionKey] = kMSACDataCosmosDbErrorResponseDesc;
  if (response) {
    userInfo[kMSCosmosDbHttpCodeKey] = @(response.statusCode);
  } else if (error.userInfo[kMSCosmosDbHttpCodeKey]) {
    userInfo[kMSCosmosDbHttpCodeKey] = error.userInfo[kMSCosmosDbHttpCodeKey];
  } else {
    userInfo[kMSCosmosDbHttpCodeKey] = @(MSHTTPCodesNo0XXInvalidUnknown);
  }
  if (error) {
    userInfo[NSUnderlyingErrorKey] = error;
  }

  // Return the error.
  return [[MSDataError alloc] initWithErrorCode:MSACDataErrorHTTPError userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
