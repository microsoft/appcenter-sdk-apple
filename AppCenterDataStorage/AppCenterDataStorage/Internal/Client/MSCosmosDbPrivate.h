// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

@interface MSCosmosDb ()

+ (NSDictionary *)defaultHeaderWithPartition:(NSString *)partition
                                     dbToken:(NSString *)dbToken
                           additionalHeaders:(NSDictionary *_Nullable)additionalHeaders;

+ (NSString *)documentUrlWithTokenResult:tokenResult documentId:(NSString *)documentId;

@end
