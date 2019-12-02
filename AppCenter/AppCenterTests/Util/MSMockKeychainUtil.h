// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSKeychainUtil.h"

@interface MSMockKeychainUtil : MSKeychainUtil

+ (void)mockStatusCode:(OSStatus)statusCode forKey:(NSString *)key;

@end
