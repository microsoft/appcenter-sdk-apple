// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@class MSException;

@interface MSCrashesTestUtil : NSObject

+ (BOOL)createTempDirectory:(NSString *)directory;

+ (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename;

+ (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename;

+ (MSException *)exception;

@end
