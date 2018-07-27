#import "MSCrashesUtil.h"
#import "MSCrashesInternal.h"
#import "MSCrashesUtilPrivate.h"
#import "MSLogger.h"
#import "MSUtility+File.h"
#import "MSUtility.h"

@implementation MSCrashesUtil

static dispatch_once_t crashesDirectoryOnceToken;
static dispatch_once_t logBufferDirectoryOnceToken;
static dispatch_once_t wrapperExceptionsDirectoryOnceToken;

#pragma mark - Public

+ (NSString *)crashesDir {
  dispatch_once(&crashesDirectoryOnceToken, ^{
    [MSUtility createDirectoryForPathComponent:kMSCrashesDirectory];
  });

  return kMSCrashesDirectory;
}

+ (NSString *)logBufferDir {
  dispatch_once(&logBufferDirectoryOnceToken, ^{
    [MSUtility createDirectoryForPathComponent:kMSLogBufferDirectory];
  });

  return kMSLogBufferDirectory;
}

+ (NSString *)wrapperExceptionsDir {
  dispatch_once(&wrapperExceptionsDirectoryOnceToken, ^{
    [MSUtility createDirectoryForPathComponent:kMSWrapperExceptionsDirectory];
  });

  return kMSWrapperExceptionsDirectory;
}

#pragma mark - Private

+ (void)resetDirectory {
  crashesDirectoryOnceToken = 0;
  logBufferDirectoryOnceToken = 0;
  wrapperExceptionsDirectoryOnceToken = 0;
}

@end
