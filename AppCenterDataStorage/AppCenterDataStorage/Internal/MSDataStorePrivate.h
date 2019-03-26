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

- (void)readWithPartition:(NSString *)partition
               documentId:(NSString *)documentId
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(MSReadOptions *_Nullable)readOptions
        continuationToken:(NSString *_Nullable)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

- (void)createWithPartition:(NSString *)partition
                 documentId:(NSString *)documentId
                   document:(id<MSSerializableDocument>)document
               writeOptions:(MSWriteOptions *_Nullable)writeOptions
          completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)replaceWithPartition:(NSString *)partition
                  documentId:(NSString *)documentId
                    document:(id<MSSerializableDocument>)document
                writeOptions:(MSWriteOptions *_Nullable)writeOptions
           completionHandler:(MSDocumentWrapperCompletionHandler)completionHandler;

- (void)deleteDocumentWithPartition:(NSString *)partition
                         documentId:(NSString *)documentId
                       writeOptions:(MSWriteOptions *_Nullable)writeOptions
                  completionHandler:(MSDataSourceErrorCompletionHandler)completionHandler;

/**
 * Method to reset the singleton when running unit tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
