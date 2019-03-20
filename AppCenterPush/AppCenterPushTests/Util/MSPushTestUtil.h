// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSPushTestUtil : NSObject

+ (NSData *)convertPushTokenToNSData:(NSString *)token;

@end
