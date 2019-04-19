// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDataOperationProxy.h"
#import "MSDataStorageConstants.h"
#import "MSDataStore.h"
#import "MSDataStoreErrors.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentUtils.h"
#import "MSDocumentWrapperInternal.h"
#import "MSLogger.h"
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
  NSInteger deviceTimeToLive = baseOptions ? baseOptions.deviceTimeToLive : kMSDataStoreTimeToLiveDefault;

  // Validate current operation.
  if (![MSDataOperationProxy isValidOperation:operation]) {
    NSString *message = @"Operation is not supported";
    MSLogError([MSDataStore logTag], message);
    completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreLocalStoreError
                                                               errorMessage:message
                                                                 documentId:documentId]);
    return;
  }

  // Retrieve a cached token.
  cachedTokenBlock(^(MSTokensResponse *_Nullable tokensResponse, NSError *_Nullable error) {
    // Handle error.
    if (error) {
      NSString *message =
          [NSString stringWithFormat:@"Error while retrieving cached token, aborting operation: %@", [error localizedDescription]];
      MSLogError([MSDataStore logTag], @"%@", message);
      completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreLocalStoreError
                                                                 errorMessage:message
                                                                   documentId:documentId]);
      return;
    }

    // Extract first token.
    MSTokenResult *token = tokensResponse.tokens.firstObject;

    // Retrieve a cached document.
    MSDocumentWrapper *cachedDocument = [self.documentStore readWithToken:token documentId:documentId documentType:documentType];

    // Execute remote operation if needed.
    if ([self shouldAttemptRemoteOperationForDocument:cachedDocument]) {
      MSLogInfo([MSDataStore logTag], @"Performing remote operation");
      remoteDocumentBlock(^(MSDocumentWrapper *_Nonnull remoteDocument) {
        // If a valid remote document was retrieved, update local store
        if (remoteDocument.error == nil) {
          [self updateLocalStore:token
              currentCachedDocument:cachedDocument
                  newCachedDocument:remoteDocument
                   deviceTimeToLive:deviceTimeToLive
                          // For online scenarios, the intended pending operation in the local store is nil.
                          operation:nil];
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
          MSLogError([MSDataStore logTag], @"Error reading document from local storage");
          completionHandler(cachedDocument);
        }

        // Cached document is pending deletion, error out.
        else if ([kMSPendingOperationDelete isEqualToString:cachedDocument.pendingOperation]) {
          NSString *message = @"Document pending deletion in local storage";
          MSLogError([MSDataStore logTag], message);
          completionHandler([[MSDocumentWrapper alloc] initWithDataStoreErrorCode:MSACDataStoreErrorDocumentNotFound
                                                                     errorMessage:message
                                                                       documentId:documentId]);
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
                                                                                            error:nil
                                                                                  fromDeviceCache:YES];

        // Update local store and return document.
        [self updateLocalStore:token
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

        // Create a create/replace document record.
        MSDocumentWrapper *createdOrUpdatedDocument = [[MSDocumentWrapper alloc] initWithDeserializedValue:document
                                                                                                 jsonValue:jsonDocument
                                                                                                 partition:token.partition
                                                                                                documentId:documentId
                                                                                                      eTag:cachedDocument.eTag
                                                                                           lastUpdatedDate:cachedDocument.lastUpdatedDate
                                                                                          pendingOperation:operation
                                                                                                     error:nil
                                                                                           fromDeviceCache:YES];

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

#pragma mark Utilities

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
 * Update the local store given a current/new cached document.
 *
 * @param token The CosmosDB token.
 * @param currentCachedDocument The current cached document.
 * @param newCachedDocument The new document that should be cached.
 * @param deviceTimeToLive The device time to live for the new cached document.
 * @param operation The operation being intended (nil - read, CREATE, UPDATE, DELETE).
 */
- (void)updateLocalStore:(MSTokenResult *)token
    currentCachedDocument:(MSDocumentWrapper *)currentCachedDocument
        newCachedDocument:(MSDocumentWrapper *)newCachedDocument
         deviceTimeToLive:(NSInteger)deviceTimeToLive
                operation:(NSString *_Nullable)operation {

  // If the device time to live does not allow it, remove document from local storage (whether it is here or not).
  if (deviceTimeToLive == kMSDataStoreTimeToLiveNoCache) {
    MSLogInfo([MSDataStore logTag], @"Removing document from local storage (partition: %@, id: %@)", token.partition,
              currentCachedDocument.documentId);
    [self.documentStore deleteWithToken:token documentId:currentCachedDocument.documentId];
  }

  /*
   * If the cached document has a create or replace pending operation, and no eTags, and if the current operation is a
   * deletion, delete the document from the store.
   */
  else if (([kMSPendingOperationCreate isEqualToString:currentCachedDocument.pendingOperation] ||
            [kMSPendingOperationReplace isEqualToString:currentCachedDocument.pendingOperation]) &&
           !currentCachedDocument.eTag && operation && [kMSPendingOperationDelete isEqualToString:(NSString *)operation]) {
    MSLogInfo([MSDataStore logTag], @"Removing never-synced document from local storage (partition: %@, id: %@)", token.partition,
              currentCachedDocument.documentId);
    [self.documentStore deleteWithToken:token documentId:currentCachedDocument.documentId];
  }

  // Update document storage.
  else {
    MSLogInfo([MSDataStore logTag], @"Updating/inserting document into local storage (partition: %@, id: %@, operation: %@)",
              token.partition, currentCachedDocument.documentId, operation);
    [self.documentStore upsertWithToken:token documentWrapper:newCachedDocument operation:operation deviceTimeToLive:deviceTimeToLive];
  }
}

@end
