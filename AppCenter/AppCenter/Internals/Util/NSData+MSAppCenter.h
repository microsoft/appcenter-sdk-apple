// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface NSData (MSAppCenter)

- (size_t)locationOfString:(NSString *)string usingEncoding:(NSStringEncoding)encoding;

- (NSString *)stringFromRange:(NSRange)range usingEncoding:(NSStringEncoding)encoding;

@end
