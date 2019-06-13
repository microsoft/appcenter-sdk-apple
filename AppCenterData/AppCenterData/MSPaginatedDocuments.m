// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSCosmosDb.h"
#import "MSData.h"
#import "MSDataInternal.h"
#import "MSPageInternal.h"
#import "MSPaginatedDocumentsInternal.h"
#import "MSSerializableDocument.h"
#import "MSTokenExchange.h"

@implementation MSPaginatedDocuments

@synthesize currentPage = _currentPage;
@synthesize continuationToken = _continuationToken;
@synthesize partition = _partition;
@synthesize documentType = _documentType;
@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *)partition
                documentType:(Class)documentType
            deviceTimeToLive:(NSInteger)deviceTimeToLive
           continuationToken:(NSString *_Nullable)continuationToken {
  if ((self = [super init])) {
    _currentPage = page;
    _partition = partition;
    _documentType = documentType;
    _deviceTimeToLive = deviceTimeToLive;
    _continuationToken = continuationToken;
  }
  return self;
}

- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentType:(Class)documentType {
  return [self initWithPage:[[MSPage alloc] initWithError:error]
                  partition:partition
               documentType:documentType
           deviceTimeToLive:0
          continuationToken:nil];
}

- (BOOL)hasNextPage {
  return [self.continuationToken length] != 0;
}

- (void)nextPageWithCompletionHandler:(void (^)(MSPage *page))completionHandler {
  if ([self hasNextPage]) {
    [MSData listDocumentsWithType:self.documentType
                        partition:self.partition
                      readOptions:[[MSReadOptions alloc] initWithDeviceTimeToLive:self.deviceTimeToLive]
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
