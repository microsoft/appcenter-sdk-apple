#import <MobileCoreServices/MobileCoreServices.h>

#import "MSCrashesUtil.h"
#import "MSUtility.h"

static NSString *const kMSCrashesDirectory = @"com.microsoft.azure.mobile.mobilecenter/crashes";
static NSString *const kMSLogBufferDirectory = @"com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer";
static NSString *const kMSWrapperExceptionsDirectory = @"com.microsoft.azure.mobile.mobilecenter/crasheswrapperexceptions";

@interface MSCrashesUtil ()

BOOL ms_isDebuggerAttached(void);

BOOL ms_isRunningInAppExtension(void);

NSString *ms_crashesDir(void);

@end

@implementation MSCrashesUtil

#pragma mark - Public

+ (NSURL *)crashesDir {
  static NSURL *crashesDir = nil;
  static dispatch_once_t predSettingsDir;

  dispatch_once(&predSettingsDir, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // temporary directory for crashes grabbed from PLCrashReporter
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    crashesDir = [cachesDirectory URLByAppendingPathComponent:kMSCrashesDirectory];

    if (![crashesDir checkResourceIsReachableAndReturnError:&error]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
      NSError *theError = NULL;

      [fileManager createDirectoryAtURL:crashesDir
            withIntermediateDirectories:YES
                             attributes:attributes
                                  error:&theError];
    }
  });

  return crashesDir;
}

+ (NSURL *)logBufferDir {
  static NSURL *logBufferDir = nil;
  static dispatch_once_t predSettingsDir;

  dispatch_once(&predSettingsDir, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // temporary directory for crashes grabbed from PLCrashReporter
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    logBufferDir = [cachesDirectory URLByAppendingPathComponent:kMSLogBufferDirectory];

    if (![logBufferDir checkResourceIsReachableAndReturnError:&error]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
      NSError *theError = nil;

      [fileManager createDirectoryAtURL:logBufferDir
            withIntermediateDirectories:YES
                             attributes:attributes
                                  error:&theError];
    }
  });

  return logBufferDir;
}

+ (NSURL *)wrapperExceptionsDir {
  static NSURL *wrapperExceptionsDir = nil;
  static dispatch_once_t predSettingsDir;

  dispatch_once(&predSettingsDir, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // temporary directory for crashes grabbed from PLCrashReporter
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    wrapperExceptionsDir = [cachesDirectory URLByAppendingPathComponent:kMSWrapperExceptionsDirectory];

    if (![wrapperExceptionsDir checkResourceIsReachableAndReturnError:&error]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
      NSError *theError = nil;

      [fileManager createDirectoryAtURL:wrapperExceptionsDir
            withIntermediateDirectories:YES
                             attributes:attributes
                                  error:&theError];
    }
  });

  return wrapperExceptionsDir;
}


@end
