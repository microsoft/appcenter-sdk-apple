// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSPaginatedDocuments.h"
#import "MSCosmosDb.h"
#import "MSData.h"
#import "MSDataErrorInternal.h"
#import "MSDataErrors.h"
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
@synthesize reachability = _reachability;
@synthesize deviceTimeToLive = _deviceTimeToLive;

- (instancetype)initWithPage:(MSPage *)page
                   partition:(NSString *)partition
                documentType:(Class)documentType
                reachability:(MS_Reachability *)reachability
            deviceTimeToLive:(NSInteger)deviceTimeToLive
           continuationToken:(NSString *_Nullable)continuationToken {
  if ((self = [super init])) {
    _currentPage = page;
    _partition = partition;
    _documentType = documentType;
    _reachability = reachability;
    _deviceTimeToLive = deviceTimeToLive;
    _continuationToken = continuationToken;
  }
  return self;
}

- (instancetype)initWithError:(MSDataError *)error partition:(NSString *)partition documentType:(Class)documentType {
  return [self initWithPage:[[MSPage alloc] initWithError:error]
                  partition:partition
               documentType:documentType
               reachability:self.reachability
           deviceTimeToLive:kMSDataTimeToLiveNoCache
          continuationToken:nil];
}

- (BOOL)hasNextPageWithError:(MSDataError *__autoreleasing *)error {
  if ([self.reachability currentReachabilityStatus] == NotReachable) {
    *error = [[MSDataError alloc] initWithErrorCode:MSACDataErrorNextDocumentPageUnavailable
                                         innerError:nil
                                            message:(NSString *)kMSACDataErrorNextDocumentPageUnavailable];
    return NO;
  }
  return [self.continuationToken length] != 0;
}

- (void)nextPageWithCompletionHandler:(void (^)(MSPage *page))completionHandler {
  NSError *error;
  if ([self hasNextPageWithError:&error] && !error) {
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
