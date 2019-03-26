// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Base URL for HTTP for token exchange.
 */
static NSString *const kMSDefaultApiUrl = @"https://api.appcenter.ms/v0.1";

@interface MSDataStore () <MSAuthTokenContextDelegate>

// TODO add docs
- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *)readOptions
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(nullable MSReadOptions *)readOptions
        continuationToken:(nullable NSString *)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;

- (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *)writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
