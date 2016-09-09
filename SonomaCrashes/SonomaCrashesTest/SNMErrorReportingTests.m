#import <Foundation/Foundation.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "SNMErrorReportingPrivate.h"

@interface SNMErrorReportingTests : XCTestCase

@property(nonatomic, strong) SNMErrorReporting *sut;

@end

@implementation SNMErrorReportingTests

#pragma mark - Houskeeping

- (void)setUp {
  [super setUp];
  self.sut = [SNMErrorReporting new];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Tests

- (void)testNewInstanceWasInitialisedCorrectly {
  assertThat(self.sut, notNilValue());
  assertThat(self.sut.fileManager, notNilValue());
  assertThat(self.sut.crashFiles, isEmpty());
  assertThat(self.sut.crashesDir, notNilValue());
  assertThat(self.sut.analyzerInProgressFile, notNilValue());
}

- (void)testStartingManagerInitializesPLCrashReporter {
  
  // When
  [self.sut startFeature];
  
  // Then
  assertThat(self.sut.plCrashReporter, notNilValue());
}

- (void)testStartingManagerWritesLastCrashReportToCrashesDir {
  //TODO reset the emulator before this runs
  assertThat(self.sut.crashFiles, hasCountOf(0));
  assertThatBool([self copyFixtureCrashReportWithFileName:@"live_report_exception"], isTrue());
  
  // When
  [self.sut startFeature];
  
  // Then
  assertThat(self.sut.crashFiles, hasCountOf(1));
}

#pragma mark - Helper

// loads test fixture from json file
// http://blog.roberthoglund.com/2010/12/ios-unit-testing-loading-bundle.html
- (NSString *)jsonFixture:(NSString *)fixture {
  NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:fixture ofType:@"json"];
  NSError *error = nil;
  NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  
  return content;
}

- (BOOL)createTempDirectory:(NSString *)directory {
  NSFileManager *fm = [[NSFileManager alloc] init];
  
  if (![fm fileExistsAtPath:directory]) {
    NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
    NSError *theError;
    [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:attributes error:&theError];
    if (theError)
      return NO;
  }
  
  return YES;
}

- (BOOL)copyFixtureCrashReportWithFileName:(NSString *)filename {
  NSFileManager *fm = [[NSFileManager alloc] init];
  
  // the bundle identifier when running with unit tets is "otest"
  const char *progname = getprogname();
  if (progname == NULL) {
    return NO;
  }
  
  NSString *bundleIdentifierPathString = [NSString stringWithUTF8String: progname];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  
  // create the PLCR cache dir
  NSString *plcrRootCrashesDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.plausiblelabs.crashreporter.data"];
  if (![self createTempDirectory:plcrRootCrashesDir])
    return NO;
  
  NSString *plcrCrashesDir = [plcrRootCrashesDir stringByAppendingPathComponent:bundleIdentifierPathString];
  if (![self createTempDirectory:plcrCrashesDir])
    return NO;
  
  NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:filename ofType:@"plcrash"];
  NSError *theError = NULL;
  
  if (!filePath) return NO;
  [fm copyItemAtPath:filePath toPath:[plcrCrashesDir stringByAppendingPathComponent:@"live_report.plcrash"] error:&theError];
  
  if (theError)
    return NO;
  else
    return YES;
}

- (NSData *)dataOfFixtureCrashReportWithFileName:(NSString *)filename {
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


@end
