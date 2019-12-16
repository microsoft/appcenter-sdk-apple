// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSHttpIngestion.h"

static NSString *const kMSOneCollectorApiKey = @"apikey";
static NSString *const kMSOneCollectorApiPath = @"/OneCollector";
static NSString *const kMSOneCollectorApiVersion = @"1.0";

/**
 * Assign value in header to avoid "format is not a string literal" warning.
 * The convention for this format string is <sdktype>-<platform>-<language>-<projection>-<version>-<tag>.
 */
static NSString *const kMSOneCollectorClientVersionFormat = @"ACS-iOS-ObjectiveC-no-%@-no";
static NSString *const kMSOneCollectorClientVersionKey = @"Client-Version";
static NSString *const kMSOneCollectorContentType = @"application/x-json-stream; charset=utf-8";
static NSString *const kMSOneCollectorLogSeparator = @"\n";
static NSString *const kMSOneCollectorTicketsKey = @"Tickets";
static NSString *const kMSOneCollectorUploadTimeKey = @"Upload-Time";

@interface MSOneCollectorIngestion : MSHttpIngestion

/**
 * Initialize the ingestion.
 *
 * @param baseUrl Base url.
 *
 * @return An ingestion instance.
 */
- (id)initWithHttpClient:(id<MSHttpClientProtocol>)httpClient baseUrl:(NSString *)baseUrl;

@end
