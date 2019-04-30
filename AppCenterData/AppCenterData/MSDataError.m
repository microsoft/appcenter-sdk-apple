// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDataError.h"
#import "MSDataErrors.h"

@implementation MSDataError

- (instancetype)initWithErrorCode:(NSInteger)errorCode innerError:(NSError *_Nullable)innerError message:(NSString *_Nullable)message {

  // Prepare user info properties.
  NSMutableDictionary *userInfo = [NSMutableDictionary new];
  if (innerError) {
    [userInfo setValue:innerError forKey:NSUnderlyingErrorKey];
  }
  if (message) {
    [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
  }

  // Return the error.
  return [super initWithDomain:kMSACDataErrorDomain code:errorCode userInfo:userInfo];
}

- (instancetype)initWithErrorCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo {

  // Return the error.
  return [super initWithDomain:kMSACDataErrorDomain code:errorCode userInfo:userInfo];
}

- (NSError *)innerError {
  return self.userInfo ? self.userInfo[NSUnderlyingErrorKey] : nil;
}

@end
