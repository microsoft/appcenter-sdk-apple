// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSData.h"
#import "MSDataConstants.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
#import "MSDataInternal.h"
#import "MSDataOperationProxy.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLogger.h"
#import "MSPageInternal.h"
#import "MSPaginatedDocumentsInternal.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"

@implementation MSDataOperationProxy : NSObject

- (instancetype)initWithDocumentStore:(id<MSDocumentStore>)documentStore reachability:(MS_Reachability *)reachability {
  self = [super init];
  if (self) {
    _documentStore = documentStore;
    _reachability = reachability;
  }
  return self;
}

- (void)performOperation:(NSString *_Nullable)operation
              documentId:(NSString *)documentId
            documentType:(Class)documentType
                document:(id<MSSerializableDocument> _Nullable)document
             baseOptions:(MSBaseOptions *_Nullable)baseOptions
        cachedTokenBlock:(void (^)(MSCachedTokenCompletionHandler))cachedTokenBlock
     remoteDocumentBlock:(void (^)(MSDocumentWrapperCompletionHandler))remoteDocumentBlock
       completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // Get effective device time to live.
  NSInteger deviceTimeToLive = baseOptions ? baseOptions.deviceTimeToLive : kMSDataTimeToLiveDefault;

  // Validate current operation.
  if (![MSDataOperationProxy isValidOperation:operation]) {
    NSString *message = @"Operation is not supported";
    MSLogError([MSData logTag], message);
    MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorUnsupportedOperation innerError:nil message:message];
    completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:nil documentId:documentId]);
    return;
  }

  // Retrieve a cached token.
  cachedTokenBlock(^(MSTokensResponse *_Nullable tokensResponse, NSError *_Nullable error) {
    // Handle error.
    if (error) {
      NSString *message =
          [NSString stringWithFormat:@"Error while retrieving cached token, aborting operation: %@", [error localizedDescription]];
      MSLogError([MSData logTag], @"%@", message);
      MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorCachedToken innerError:nil message:message];
      completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:nil documentId:documentId]);
      return;
    }

    // Extract first token.
    MSTokenResult *token = tokensResponse.tokens.firstObject;

    // Retrieve a cached document.
    MSDocumentWrapper *cachedDocument = [self.documentStore readWithToken:token documentId:documentId documentType:documentType];

    // Execute remote operation if needed.
    if ([self shouldAttemptRemoteOperationForDocument:cachedDocument]) {

      // Create document wrapper for current document.
      if (operation != kMSPendingOperationRead) {
        NSDictionary *pendingDocDictionary = [document serializeToDictionary];
        if (deviceTimeToLive == kMSDataTimeToLiveNoCache) {
          pendingDocDictionary = nil;
        }
        MSDocumentWrapper *pendingDocumentWrapper = [MSDocumentUtils documentWrapperFromDictionary:pendingDocDictionary
                                                                                      documentType:documentType
                                                                                              eTag:cachedDocument.eTag
                                                                                   lastUpdatedDate:cachedDocument.lastUpdatedDate
                                                                                         partition:token.partition
                                                                                        documentId:documentId
                                                                                  pendingOperation:operation
                                                                                   fromDeviceCache:YES];

        // If the operation is delete we don't want the document in the table to get cleaned up yet.
        if ([operation isEqualToString:kMSPendingOperationDelete]) {
          pendingDocumentWrapper = cachedDocument;
          pendingDocumentWrapper.pendingOperation = operation;
        }

        // Store the operation in DB and mark as pending.
        [self.documentStore upsertWithToken:token
                            documentWrapper:pendingDocumentWrapper
                                  operation:operation
                           deviceTimeToLive:deviceTimeToLive];
      }

      MSLogInfo([MSData logTag], @"Performing remote operation");
      remoteDocumentBlock(^(MSDocumentWrapper *_Nonnull remoteDocument) {
        // If a valid remote document was retrieved, update local store
        if (remoteDocument.error == nil) {

          // If operation is delete, directly delete the document from the local cache.
          if ([kMSPendingOperationDelete isEqualToString:(NSString *)operation]) {
            MSLogInfo([MSData logTag], @"Delete the document from local storage (partition: %@, id: %@)", token.partition,
                      cachedDocument.documentId);
            [self.documentStore deleteWithToken:token documentId:cachedDocument.documentId];
          }
          // For other online scenarios, the intended pending operation in the local store is nil.
          else {
            [self.documentStore updateDocumentWithToken:token
                                  currentCachedDocument:cachedDocument
                                      newCachedDocument:remoteDocument
                                       deviceTimeToLive:deviceTimeToLive
                                              operation:nil];
          }
        }
        completionHandler(remoteDocument);
      });
    }

    // Use cached document if possible.
    else {

      // Read operation.
      if (operation == kMSPendingOperationRead) {

        // Cached document is invalid, error out.
        if (cachedDocument.error) {
          MSLogError([MSData logTag], @"Error reading document from local storage");
          completionHandler(cachedDocument);
        }

        // Cached document is pending deletion, error out.
        else if ([kMSPendingOperationDelete isEqualToString:cachedDocument.pendingOperation]) {
          NSString *message = @"Document pending deletion in local storage";
          MSLogError([MSData logTag], message);
          MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorDocumentNotFound innerError:nil message:message];
          completionHandler([[MSDocumentWrapper alloc] initWithError:dataError partition:nil documentId:documentId]);
        }

        // Cached document is valid.
        else {

          // Push back cached document expiration time then return it.
          [self.documentStore updateDocumentWithToken:token
                                currentCachedDocument:cachedDocument
                                    newCachedDocument:cachedDocument
                                     deviceTimeToLive:deviceTimeToLive
                                            operation:cachedDocument.pendingOperation];
          completionHandler(cachedDocument);
        }
      }

      // Delete operation.
      else if ([kMSPendingOperationDelete isEqualToString:(NSString *)operation]) {

        // Create a deleted document record.
        MSDocumentWrapper *deletedDocument = [[MSDocumentWrapper alloc] initWithDeserializedValue:nil
                                                                                        jsonValue:nil
                                                                                        partition:token.partition
                                                                                       documentId:documentId
                                                                                             eTag:cachedDocument.eTag
                                                                                  lastUpdatedDate:cachedDocument.lastUpdatedDate
                                                                                 pendingOperation:operation
                                                                                  fromDeviceCache:YES];

        // Update local store and return document.
        [self.documentStore updateDocumentWithToken:token
                              currentCachedDocument:cachedDocument
                                  newCachedDocument:deletedDocument
                                   deviceTimeToLive:deviceTimeToLive
                                          operation:operation];
        completionHandler(deletedDocument);
      }

      // Create/Replace operation.
      else if ([kMSPendingOperationCreate isEqualToString:(NSString *)operation] ||
               [kMSPendingOperationReplace isEqualToString:(NSString *)operation]) {

        // Serialize incoming document into a JSON string.
        NSDictionary *dictionary = [document serializeToDictionary];
        MSDocumentWrapper *documentWrapper = [MSDocumentUtils documentWrapperFromDictionary:dictionary
                                                                               documentType:documentType
                                                                                       eTag:cachedDocument.eTag
                                                                            lastUpdatedDate:cachedDocument.lastUpdatedDate
                                                                                  partition:token.partition
                                                                                 documentId:documentId
                                                                           pendingOperation:operation
                                                                            fromDeviceCache:YES];

        // Update local store and return document.
        [self.documentStore updateDocumentWithToken:token
                              currentCachedDocument:cachedDocument
                                  newCachedDocument:documentWrapper
                                   deviceTimeToLive:deviceTimeToLive
                                          operation:operation];
        completionHandler(documentWrapper);
      }
    }
  });
}

- (void)listDocumentsWithType:(Class)documentType
                    partition:(NSString *)partition
                  baseOptions:(MSBaseOptions *_Nullable)baseOptions
             cachedTokenBlock:(void (^)(MSCachedTokenCompletionHandler))cachedTokenBlock
          remoteDocumentBlock:(void (^)(MSPaginatedDocumentsCompletionHandler))remoteDocumentBlock
            completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler {

  // Retrieve a cached token.
  cachedTokenBlock(^(MSTokensResponse *_Nullable tokensResponse, NSError *_Nullable error) {
    // Handle error.
    if (error) {
      NSString *message =
          [NSString stringWithFormat:@"Error while retrieving cached token, aborting operation: %@", [error localizedDescription]];
      MSLogError([MSData logTag], @"%@", message);
      MSDataError *dataError = [[MSDataError alloc] initWithErrorCode:MSACDataErrorCachedToken innerError:nil message:message];
      MSPaginatedDocuments *documents = [[MSPaginatedDocuments alloc] initWithError:dataError
                                                                          partition:partition
                                                                       documentType:documentType
                                                                  continuationToken:nil];
      completionHandler(documents);
      return;
    }

    // Extract first token.
    MSTokenResult *token = tokensResponse.tokens.firstObject;

    // Retrieve from cache when offline and when there are pending operations.
    if (![self shouldAttemptRemoteOperationForPartition:[token partition]]) {
      MSPaginatedDocuments *cachedDocumentsList = [self.documentStore listWithToken:token
                                                                          partition:partition
                                                                       documentType:documentType
                                                                        baseOptions:baseOptions];
      if ([self.reachability currentReachabilityStatus] != NotReachable && [[cachedDocumentsList currentPage] items].count == 0) {
        MSLogInfo([MSData logTag], @"Performing remote operation, since the local list is empty");
        [self performRemoteOperationWithToken:token
                                  baseOptions:baseOptions
                          remoteDocumentBlock:remoteDocumentBlock
                            completionHandler:completionHandler];
        return;
      }
      completionHandler(cachedDocumentsList);
      return;
    }

    // Execute remote operation online and does not have any pending operations.
    else {
      MSLogInfo([MSData logTag], @"Performing remote operation");
      [self performRemoteOperationWithToken:token
                                baseOptions:baseOptions
                        remoteDocumentBlock:remoteDocumentBlock
                          completionHandler:completionHandler];
      return;
    }
  });
}

#pragma mark Utilities

- (void)performRemoteOperationWithToken:(MSTokenResult *)token
                            baseOptions:(MSBaseOptions *_Nullable)baseOptions
                    remoteDocumentBlock:(void (^)(MSPaginatedDocumentsCompletionHandler))remoteDocumentBlock
                      completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler

{
  remoteDocumentBlock(^(MSPaginatedDocuments *_Nonnull remoteDocuments) {
    // Update local store with the remote list of documents.
    [self.documentStore updateDocumentsWithToken:token remoteDocuments:remoteDocuments baseOptions:baseOptions];
    completionHandler(remoteDocuments);
  });
}
/**
 * Validate an operation.
 *
 *@param operation The operation.
 *
 *@return YES if the operation is valid; NO otherwise.
 */
+ (BOOL)isValidOperation:(NSString *)operation {
  return operation == kMSPendingOperationRead || [kMSPendingOperationCreate isEqualToString:operation] ||
         [kMSPendingOperationReplace isEqualToString:operation] || [kMSPendingOperationDelete isEqualToString:operation];
}

/**
 * Returns a flag indicating if a remote operation should be attempted.
 *
 * @param document The current cached document (if any).
 *
 * @return YES if a remote operation should be attempted; NO otherwise.
 */
- (BOOL)shouldAttemptRemoteOperationForDocument:(MSDocumentWrapper *)document {
  return [self.reachability currentReachabilityStatus] != NotReachable && document.pendingOperation == nil;
}

/**
 * Returns a flag indicating if a remote operation should be attempted.
 *
 * @param partition The partition under which to check for pending operations.
 *
 * @return YES if a remote operation should be attempted; NO otherwise.
 */
- (BOOL)shouldAttemptRemoteOperationForPartition:(NSString *)partition {
  return [self.reachability currentReachabilityStatus] != NotReachable && ![self.documentStore hasPendingOperationsForPartition:partition];
}

@end
