// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSCosmosDb.h"
#import "MSCosmosDbIngestion.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDataStorePrivate.h"
#import "MSSerializableDocument.h"
#import "MSTokenExchange.h"

// Redefine readonly properties to be locally readwrite-able.
@interface MSPaginatedDocuments ()

@property(nonatomic, strong, readwrite) MSPage *currentPage;
@property(nonatomic, strong, readwrite, nullable) NSString *continuationToken;

@end

@implementation MSPaginatedDocuments

@synthesize currentPage = _currentPage;
@synthesize continuationToken = _continuationToken;
@synthesize partition = _partition;
@synthesize documentType = _documentType;
@synthesize readOptions = _readOptions;

- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *)partition
                documentType:(Class)documentType
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
  if ((self = [super init])) {
    _currentPage = page;
    _continuationToken = nil;
  }
  return self;
}

- (instancetype)initWithError:(MSDataSourceError *)error {
  if ((self = [super init])) {
    MSPage *pageWithError = [[MSPage alloc] initWithError:error];
    return [self initWithPage:pageWithError];
  }
  return self;
}

- (BOOL)hasNextPage {
  return self.continuationToken.length;
}

- (void)nextPageWithCompletionHandler:(void (^)(MSPage<id<MSSerializableDocument>> *page))completionHandler {
  if ([self hasNextPage]) {
    [MSDataStore listWithPartition:self.partition
                      documentType:self.documentType
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
