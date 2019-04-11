// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSCosmosDb.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSPaginatedDocumentsInternal.h"
#import "MSSerializableDocument.h"
#import "MSTokenExchange.h"

@implementation MSPaginatedDocuments

@synthesize currentPage = _currentPage;
@synthesize continuationToken = _continuationToken;
@synthesize partition = _partition;
@synthesize documentType = _documentType;
@synthesize readOptions = _readOptions;

- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *_Nullable)partition
                documentType:(Class _Nullable)documentType
                 readOptions:(MSReadOptions *_Nullable)readOptions
           continuationToken:(NSString *_Nullable)continuationToken {
  if ((self = [super init])) {
    _currentPage = page;
    _partition = partition;
    _documentType = documentType;
    _readOptions = readOptions;
    _continuationToken = continuationToken;
  }
  return self;
}

- (instancetype)initWithPage:(MSPage *)page {
  return [self initWithPage:page partition:nil documentType:nil readOptions:nil continuationToken:nil];
}

- (instancetype)initWithError:(MSDataSourceError *)error {
  return [self initWithPage:[[MSPage alloc] initWithError:error]];
}

- (BOOL)hasNextPage {
  return [self.continuationToken length] != 0;
}

- (void)nextPageWithCompletionHandler:(void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  if ([self hasNextPage]) {
    [MSDataStore listWithPartition:(NSString *)self.partition
                      documentType:(Class)self.documentType
                       readOptions:nil
                 continuationToken:self.continuationToken
                 completionHandler:^(MSPaginatedDocuments *documents) {
                   // Update current page and continuation token.
                   self.currentPage = documents.currentPage;
                   self.continuationToken = documents.continuationToken;

                   // Notify completion handler.
                   completionHandler(documents.currentPage);
                 }];
  } else {
    completionHandler(nil);
  }
}

@end
