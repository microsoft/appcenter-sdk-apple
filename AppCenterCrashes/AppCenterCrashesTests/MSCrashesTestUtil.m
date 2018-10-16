#import "MSCrashesTestUtil.h"
#import "MSException.h"
#import "MSStackFrame.h"

@implementation MSCrashesTestUtil

+ (BOOL)createTempDirectory:(NSString *)directory {
  NSFileManager *fm = [[NSFileManager alloc] init];

  if (![fm fileExistsAtPath:directory]) {
    NSDictionary *attributes = @{ NSFilePosixPermissions : @0755 };
    NSError *error;
    [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:attributes error:&error];
    if (error)
      return NO;
  }

  return YES;
}

+ (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename {
  NSFileManager *fm = [[NSFileManager alloc] init];

  // the bundle identifier when running with unit tests is "otest"
  const char *progName = getprogname();
  if (progName == NULL) {
    return NO;
  }

  NSString *bundleIdentifierPathString = [NSString stringWithUTF8String:progName];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

  // create the PLCR cache dir
  NSString *plcrRootCrashesDir = [paths[0] stringByAppendingPathComponent:@"com.plausiblelabs.crashreporter.data"];
  if (![MSCrashesTestUtil createTempDirectory:plcrRootCrashesDir])
    return NO;

  NSString *plcrCrashesDir = [plcrRootCrashesDir stringByAppendingPathComponent:bundleIdentifierPathString];
  if (![MSCrashesTestUtil createTempDirectory:plcrCrashesDir])
    return NO;

  NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:filename ofType:@"plcrash"];
  if (!filePath)
    return NO;

  NSError *error = nil;
  [fm copyItemAtPath:filePath toPath:[plcrCrashesDir stringByAppendingPathComponent:@"live_report.plcrash"] error:&error];
  return error == nil;
}

+ (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename {

  // the bundle identifier when running with unit tets is "otest"
  const char *progname = getprogname();
  if (progname == NULL) {
    return nil;
  }
  NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:filename ofType:@"plcrash"];
  if (!filePath) {
    return nil;
  } else {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return data;
  }
}

+ (MSException *)exception {
  NSString *type = @"exceptionType";
  NSString *message = @"message";
  NSString *stackTrace = @"at (wrapper managed-to-native) UIKit.UIApplication:UIApplicationMain "
                         @"(int,string[],intptr,intptr) \n at UIKit.UIApplication.Main "
                         @"(System.String[] args, "
                         @"System.IntPtr principal, System.IntPtr delegate) [0x00005] in "
                         @"/Users/builder/data/lanes/3969/44931ae8/source/xamarin-macios/src/"
                         @"UIKit/"
                         @"UIApplication.cs:79 \n at UIKit.UIApplication.Main (System.String[] "
                         @"args, System.String "
                         @"principalClassName, System.String delegateClassName) [0x00038] in "
                         @"/Users/builder/data/lanes/3969/44931ae8/source/xamarin-macios/src/"
                         @"UIKit/"
                         @"UIApplication.cs:63 \n   at HockeySDKXamarinDemo.Application.Main "
                         @"(System.String[] args) "
                         @"[0x00008] in "
                         @"/Users/benny/Repositories/MS/HockeySDK-XamarinDemo/iOS/Main.cs:17";
  NSString *wrapperSdkName = @"appcenter.xamarin";
  MSStackFrame *frame = [MSStackFrame new];
  frame.address = @"frameAddress";
  frame.code = @"frameSymbol";
  NSArray<MSStackFrame *> *frames = @[ frame ];

  MSException *exception = [MSException new];
  exception.type = type;
  exception.message = message;
  exception.stackTrace = stackTrace;
  exception.wrapperSdkName = wrapperSdkName;
  exception.frames = frames;

  return exception;
}

@end
