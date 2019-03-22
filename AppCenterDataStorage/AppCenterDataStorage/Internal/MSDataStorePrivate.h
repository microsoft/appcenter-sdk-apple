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

+ (void)listWithPartition:(NSString *)partition
             documentType:(Class)documentType
              readOptions:(nullable MSReadOptions *)readOptions
        continuationToken:(nullable NSString *)continuationToken
        completionHandler:(MSPaginatedDocumentsCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
