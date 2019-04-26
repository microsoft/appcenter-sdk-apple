// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"
#import "MSDataErrors.h"

@implementation MSDataError

- (instancetype)initWithInnerError:(NSError *_Nullable)innerError code:(NSInteger)code message:(NSString *_Nullable)message {

  // Prepare user info properties.
  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  if (innerError) {
    [userInfo setValue:innerError forKey:NSUnderlyingErrorKey];
  }
  if (message) {
    [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
  }

  // Return the error.
  return [super initWithDomain:kMSACDataErrorDomain code:code userInfo:userInfo];
}

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo code:(NSInteger)code {

  // Return the error.
  return [super initWithDomain:kMSACDataErrorDomain code:code userInfo:userInfo];
}

- (NSError *)innerError {
  return self.userInfo ? self.userInfo[NSUnderlyingErrorKey] : nil;
}

@end
