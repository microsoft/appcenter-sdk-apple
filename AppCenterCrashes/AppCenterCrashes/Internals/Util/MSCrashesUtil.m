#import "MSCrashesInternal.h"
#import "MSCrashesUtil.h"
#import "MSCrashesUtilPrivate.h"
#import "MSLogger.h"
#import "MSUtility.h"

static NSString *const kMSCrashesDirectory = @"com.microsoft.azure.mobile.mobilecenter/crashes";
static NSString *const kMSLogBufferDirectory = @"com.microsoft.azure.mobile.mobilecenter/crasheslogbuffer";
static NSString *const kMSWrapperExceptionsDirectory =
    @"com.microsoft.azure.mobile.mobilecenter/crasheswrapperexceptions";

@interface MSCrashesUtil ()

BOOL ms_isDebuggerAttached(void);

BOOL ms_isRunningInAppExtension(void);

NSString *ms_crashesDir(void);

@end

@implementation MSCrashesUtil

static dispatch_once_t crashesDirectoryOnceToken;
static dispatch_once_t logBufferDirectoryOnceToken;
static dispatch_once_t wrapperExceptionsDirectoryOnceToken;

#pragma mark - Public

+ (NSURL *)crashesDir {
  static NSURL *crashesDir = nil;

  dispatch_once(&crashesDirectoryOnceToken, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // Temporary directory for crashes grabbed from PLCrashReporter.
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
#if TARGET_OS_OSX

    // To prevent placing all logs to the same place if host application doesn't enable sandbox.
    cachesDirectory = [cachesDirectory
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/", [MS_APP_MAIN_BUNDLE bundleIdentifier]]];
#endif
    crashesDir = [cachesDirectory URLByAppendingPathComponent:kMSCrashesDirectory];

    if (![crashesDir checkResourceIsReachableAndReturnError:nil]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
      if (![fileManager createDirectoryAtURL:crashesDir
                 withIntermediateDirectories:YES
                                  attributes:attributes
                                       error:&error]) {
        MSLogError([MSCrashes logTag], @"Couldn't create crashes directory at %@: %@", crashesDir,
                   error.localizedDescription);
      }
    }
  });

  return crashesDir;
}

+ (NSURL *)logBufferDir {
  static NSURL *logBufferDir = nil;

  dispatch_once(&logBufferDirectoryOnceToken, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // Temporary directory for crashes grabbed from PLCrashReporter.
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
#if TARGET_OS_OSX

    // To prevent placing all logs to the same place if host application doesn't enable sandbox.
    cachesDirectory = [cachesDirectory
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/", [MS_APP_MAIN_BUNDLE bundleIdentifier]]];
#endif
    logBufferDir = [cachesDirectory URLByAppendingPathComponent:kMSLogBufferDirectory];

    if (![logBufferDir checkResourceIsReachableAndReturnError:nil]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
      if (![fileManager createDirectoryAtURL:logBufferDir
                 withIntermediateDirectories:YES
                                  attributes:attributes
                                       error:&error]) {
        MSLogError([MSCrashes logTag], @"Couldn't create log buffer directory at %@: %@", logBufferDir,
                   error.localizedDescription);
      }
    }
  });

  return logBufferDir;
}

+ (NSURL *)wrapperExceptionsDir {
  static NSURL *wrapperExceptionsDir = nil;

  dispatch_once(&wrapperExceptionsDirectoryOnceToken, ^{
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    // Temporary directory for crashes grabbed from PLCrashReporter.
    NSURL *cachesDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
#if TARGET_OS_OSX

    // To prevent placing all logs to the same place if host application doesn't enable sandbox.
    cachesDirectory = [cachesDirectory
        URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/", [MS_APP_MAIN_BUNDLE bundleIdentifier]]];
#endif
    wrapperExceptionsDir = [cachesDirectory URLByAppendingPathComponent:kMSWrapperExceptionsDirectory];

    if (![wrapperExceptionsDir checkResourceIsReachableAndReturnError:nil]) {
      NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };

      if (![fileManager createDirectoryAtURL:wrapperExceptionsDir
                 withIntermediateDirectories:YES
                                  attributes:attributes
                                       error:&error]) {
        MSLogError([MSCrashes logTag], @"Couldn't create wrapper exceptions directory at %@: %@", wrapperExceptionsDir,
                   error.localizedDescription);
      }
    }
  });

  return wrapperExceptionsDir;
}

#pragma mark - Private

+ (void)resetDirectory {
  crashesDirectoryOnceToken = 0;
  logBufferDirectoryOnceToken = 0;
  wrapperExceptionsDirectoryOnceToken = 0;
}

@end
