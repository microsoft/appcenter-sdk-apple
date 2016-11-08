/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashesTestHelper.h"
#import "MSException.h"
#import "MSStackFrame.h"

@implementation MSCrashesTestHelper

// loads test fixture from json file
// http://blog.roberthoglund.com/2010/12/ios-unit-testing-loading-bundle.html
+ (NSString *)jsonFixture:(NSString *)fixture {
  NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:fixture ofType:@"json"];
  NSError *error = nil;
  NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

  if (error) {
    NSLog(@"Couldn't load fixture with error: %@", error.localizedDescription);
  }

  return content;
}

- (BOOL)createTempDirectory:(NSString *)directory {
  NSFileManager *fm = [[NSFileManager alloc] init];

  if (![fm fileExistsAtPath:directory]) {
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:NSFilePosixPermissions];
    NSError *error;
    [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:attributes error:&error];
    if (error)
      return NO;
  }

  return YES;
}

+ (BOOL)createTempDirectory:(NSString *)directory {
  NSFileManager *fm = [[NSFileManager alloc] init];

  if (![fm fileExistsAtPath:directory]) {
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0755] forKey:NSFilePosixPermissions];
    NSError *error;
    [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:attributes error:&error];
    if (error)
      return NO;
  }

  return YES;
}

+ (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename {
  NSFileManager *fm = [[NSFileManager alloc] init];

  // the bundle identifier when running with unit tets is "otest"
  const char *progname = getprogname();
  if (progname == NULL) {
    return NO;
  }

  NSString *bundleIdentifierPathString = [NSString stringWithUTF8String:progname];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

  // create the PLCR cache dir
  NSString *plcrRootCrashesDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.plausiblelabs.crashreporter.data"];
  if (![MSCrashesTestHelper createTempDirectory:plcrRootCrashesDir])
    return NO;

  NSString *plcrCrashesDir = [plcrRootCrashesDir stringByAppendingPathComponent:bundleIdentifierPathString];
  if (![MSCrashesTestHelper createTempDirectory:plcrCrashesDir])
    return NO;

  NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:filename ofType:@"plcrash"];
  NSError *error = NULL;

  if (!filePath) return NO;
  [fm copyItemAtPath:filePath toPath:[plcrCrashesDir stringByAppendingPathComponent:@"live_report.plcrash"] error:&error];

  if (error)
    return NO;
  else
    return YES;
}

+ (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename {
  // the bundle identifier when running with unit tets is "otest"
  const char *progname = getprogname();
  if (progname == NULL) {
    return nil;
  }
  NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:filename ofType:@"plcrash"];
  if (!filePath) return nil;
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  return data;
}

+ (MSException *)exception {
  NSString *type = @"exception_type";
  NSString *message = @"message";
  NSString *wrapperSdkName = @"mobilecenter.xamarin";
  MSStackFrame *frame = [MSStackFrame new];
  frame.address = @"frameAddress";
  frame.code = @"frameSymbol";
  NSArray<MSStackFrame *> *frames = [NSArray arrayWithObject:frame];

  MSException *exception = [MSException new];
  exception.type = type;
  exception.message = message;
  exception.wrapperSdkName = wrapperSdkName;
  exception.frames = frames;

  return exception;
}

@end
