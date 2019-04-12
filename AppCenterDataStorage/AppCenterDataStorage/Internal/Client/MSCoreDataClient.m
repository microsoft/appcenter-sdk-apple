// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSCoreDataClient.h"
#import "MSDataStorageConstants.h"
#import "MSDataStore.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLogger.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"

@implementation MSCoreDataClient : NSObject

- (instancetype)initWithDocumentStore:(id<MSDocumentStore>)documentStore {
  self = [super init];
  if (self) {
    _documentStore = documentStore;
    _reachability = [MS_Reachability reachabilityForInternetConnection];
  }
  return self;
}

- (void)performCoreOperation:(NSString *_Nullable)operation
                  documentId:(NSString *)documentId
                documentType:(Class)documentType
                    document:(id<MSSerializableDocument> _Nullable)document
                 baseOptions:(MSBaseOptions *_Nullable)baseOptions
            cachedTokenBlock:(void (^)(MSCachedTokenCompletionHandler))cachedTokenBlock
         remoteDocumentBlock:(void (^)(MSDocumentWrapperCompletionHandler))remoteDocumentBlock
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler {

  // Get effective device time to live.
  NSInteger deviceTimeToLive = baseOptions ? baseOptions.deviceTimeToLive : MSDataStoreTimeToLiveDefault;

  // Validate current operation.
  if (![MSCoreDataClient isValidOperation:operation]) {
    NSString *message = @"Operation is not supported";
    MSLogError([MSDataStore logTag], message);
    completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreLocalStoreError
                                                               errorMessage:message
                                                                 documentId:documentId]);
    return;
  }

  //
  // Retrieve a cached token.
  //
  cachedTokenBlock(^(MSTokensResponse *_Nullable tokens, NSError *_Nullable error) {
    // Handle error.
    if (error) {
      NSString *message = @"Error while retrieving cached token, abording operation";
      MSLogError([MSDataStore logTag], message);
      completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreLocalStoreError
                                                                 errorMessage:message
                                                                   documentId:documentId]);
      return;
    }

    // Extract token.
    MSTokenResult *token = tokens.tokens[0];

    //
    // Retrieve a cached document.
    //
    MSDocumentWrapper *cachedDocument = [self.documentStore readWithToken:token documentId:documentId documentType:documentType];

    //
    // Execute remote operation if needed.
    //
    if ([self needsRemoteOperation:cachedDocument]) {
      MSLogInfo([MSDataStore logTag], @"Performing remote operation");
      remoteDocumentBlock(^(MSDocumentWrapper *_Nonnull remoteDocument) {
        // If a valid remote document was retrieved, update local store
        if (remoteDocument.error == nil) {
          [self updateLocalStore:token
              currentCachedDocument:cachedDocument
                  newCachedDocument:remoteDocument
                   deviceTimeToLive:deviceTimeToLive
                          operation:operation];
        }

        // Complete the operation.
        completionHandler(remoteDocument);
      });
    }

    //
    // Use cached document if possible.
    //
    else {
      // Read operation.
      if (operation == nil) {
        // Cached document is invalid, error out.
        if (cachedDocument.error) {
          MSLogError([MSDataStore logTag], @"Error reading document from local storage");
          completionHandler(cachedDocument);
        }

        // Cached document is valid.
        else {
          // Push back cached document expiration time then return it.
          [self updateLocalStore:token
              currentCachedDocument:cachedDocument
                  newCachedDocument:cachedDocument
                   deviceTimeToLive:deviceTimeToLive
                          operation:operation];
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
                                                                                            error:nil];
        // Update local store and return document.
        [self updateLocalStore:token
            currentCachedDocument:cachedDocument
                newCachedDocument:deletedDocument
                 deviceTimeToLive:deviceTimeToLive
                        operation:operation];
        // WIP: fix public deletion not to return error when it worked.
        completionHandler(deletedDocument);
      }

      // Create/Replace operation.
      else if ([kMSPendingOperationCreate isEqualToString:(NSString *)operation] ||
               [kMSPendingOperationReplace isEqualToString:(NSString *)operation]) {

        // Serialize incoming document into a JSON string.
        NSDictionary *dictionary = [document serializeToDictionary];
        NSString *jsonDocument;
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&jsonError];
        if (!error) {
          jsonDocument = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        } else {
          NSString *message = @"Error serializing document for local storage";
          MSLogError([MSDataStore logTag], message);
          completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreLocalStoreError
                                                                     errorMessage:message
                                                                       documentId:documentId]);
          return;
        }

        // Create a deleted document record.
        MSDocumentWrapper *createdOrUpdatedDocument = [[MSDocumentWrapper alloc] initWithDeserializedValue:document
                                                                                                 jsonValue:jsonDocument
                                                                                                 partition:token.partition
                                                                                                documentId:documentId
                                                                                                      eTag:cachedDocument.eTag
                                                                                           lastUpdatedDate:cachedDocument.lastUpdatedDate
                                                                                          pendingOperation:operation
                                                                                                     error:nil];
        // Update local store and return document.
        [self updateLocalStore:token
            currentCachedDocument:cachedDocument
                newCachedDocument:createdOrUpdatedDocument
                 deviceTimeToLive:deviceTimeToLive
                        operation:operation];
        completionHandler(createdOrUpdatedDocument);
      }
    }
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
  return operation == nil || [kMSPendingOperationCreate isEqualToString:operation] ||
         [kMSPendingOperationReplace isEqualToString:operation] || [kMSPendingOperationDelete isEqualToString:operation];
}

/**
 * Returns a flag indicating if a remote operation should be attempted.
 *
 * @param cachedDocument The current cached document (if any).
 *
 * @return YES if a remote operation should be attempted; NO otherwise.
 */
- (BOOL)needsRemoteOperation:(MSDocumentWrapper *)cachedDocument {
  return // Not offline
      [self.reachability currentReachabilityStatus] != NotReachable
      // And no pending operation on cached document
      && cachedDocument.pendingOperation == nil;
}

- (void)updateLocalStore:(MSTokenResult *)token
    currentCachedDocument:(MSDocumentWrapper *)currentCachedDocument
        newCachedDocument:(MSDocumentWrapper *)newCachedDocument
         deviceTimeToLive:(NSInteger)deviceTimeToLive
                operation:(NSString *_Nullable)operation {

  // If the device time to live does not allow it, do not touch the local storage.
  if (deviceTimeToLive == MSDataStoreTimeToLiveNoCache) {
    return;
  }

  // If the cached document has a create or replace pending operation, no etags and if the current operation is a
  // deletion, delete the document from the store.
  // WIP: Extract that condition to a static method (just like the remote caching stuff).
  if (([kMSPendingOperationCreate isEqualToString:currentCachedDocument.pendingOperation] ||
       [kMSPendingOperationReplace isEqualToString:currentCachedDocument.pendingOperation]) &&
      !currentCachedDocument.eTag && operation && [kMSPendingOperationDelete isEqualToString:(NSString *)operation]) {
    MSLogInfo([MSDataStore logTag], @"Removing (never-synced) document from local storage");
    [self.documentStore deleteWithToken:token documentId:currentCachedDocument.documentId];
  }

  // Update document storage.
  else {
    MSLogInfo([MSDataStore logTag], @"Updating/inserting document into local storage");
    [self.documentStore upsertWithToken:token documentWrapper:newCachedDocument operation:operation deviceTimeToLive:deviceTimeToLive];
  }
}

@end
