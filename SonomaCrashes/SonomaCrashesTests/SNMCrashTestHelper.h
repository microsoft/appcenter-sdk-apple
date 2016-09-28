/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface SNMCrashTestHelper : NSObject

+ (id)jsonFixture:(NSString *)fixture;
+ (BOOL)createTempDirectory:(NSString *)directory;
+ (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename;
+ (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename;

@end
