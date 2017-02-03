/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashesUtil.h"

static NSString *const kMSCrashesDirectory = @"com.microsoft.azure.mobile.mobilecenter/crashes";
static NSString *const kMSLogBufferDirectory = @"com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer";

@interface MSCrashesUtil ()

BOOL ms_isDebuggerAttached(void);
BOOL ms_isRunningInAppExtension(void);
NSString *ms_crashesDir(void);

@end

@implementation MSCrashesUtil

#pragma mark - Public

+ (NSString *)crashesDir {
  static NSString *crashesDir = nil;
  static dispatch_once_t predSettingsDir;

  dispatch_once(&predSettingsDir, ^{
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // temporary directory for crashes grabbed from PLCrashReporter
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    crashesDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:kMSCrashesDirectory];

    if (![fileManager fileExistsAtPath:crashesDir]) {
      NSDictionary *attributes =
          [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:NSFilePosixPermissions];
      NSError *theError = NULL;

      [fileManager createDirectoryAtPath:crashesDir
             withIntermediateDirectories:YES
                              attributes:attributes
                                   error:&theError];
    }
  });

  return crashesDir;
}

+ (NSString *)logBufferDir {
  static NSString *logBufferDir = nil;
  static dispatch_once_t predSettingsDir;
  
  dispatch_once(&predSettingsDir, ^{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    // temporary directory for crashes grabbed from PLCrashReporter
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    logBufferDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:kMSLogBufferDirectory];
    
    if (![fileManager fileExistsAtPath:logBufferDir]) {
      NSDictionary *attributes =
      [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:NSFilePosixPermissions];
      NSError *theError = NULL;
      
      [fileManager createDirectoryAtPath:logBufferDir
             withIntermediateDirectories:YES
                              attributes:attributes
                                   error:&theError];
    }
  });
  
  return logBufferDir;
}

@end
