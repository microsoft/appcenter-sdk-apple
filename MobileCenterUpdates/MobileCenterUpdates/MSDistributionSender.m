/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSDistributionSender.h"
#import "MSLogger.h"
#import "MSMobileCenter.h"
#import "MSHttpSenderPrivate.h"
#import "MSMobileCenterInternal.h"

@implementation MSDistributionSender

- (NSURLRequest *)createRequest:(NSObject *)data {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sendURL];

  // Set method.
  request.HTTPMethod = @"GET";

  // Set Header params.
  request.allHTTPHeaderFields = self.httpHeaders;

  // Set body.
  request.HTTPBody = nil;

  // Always disable cookies.
  [request setHTTPShouldHandleCookies:NO];

  // Don't loose time pretty printing headers if not going to be printed.
  if ([MSLogger currentLogLevel] <= MSLogLevelVerbose) {
    MSLogVerbose([MSMobileCenter logTag], @"URL: %@", request.URL);
    MSLogVerbose([MSMobileCenter logTag], @"Headers: %@", [super prettyPrintHeaders:request.allHTTPHeaderFields]);
  }

  return request;
}

@end
