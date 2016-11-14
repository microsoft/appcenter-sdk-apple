/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperExceptionManager.h"
#import "MSCrashes.h"
#import "MSException.h"
#import "MSCrashesInternal.h"

@interface MSWrapperExceptionManager ()

@property MSException *wrapperException;
@property NSMutableDictionary *wrapperExceptionData;
@property CFUUIDRef currentUUIDRef;

+ (MSWrapperExceptionManager*)sharedInstance;
- (BOOL)hasException;
- (MSException*)loadWrapperException:(CFUUIDRef)uuidRef;
- (void)saveWrapperException:(CFUUIDRef)uuidRef;
- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;
- (void)deleteAllWrapperExceptions;

- (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef;

- (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString;
- (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString;

+ (NSString*)directoryPath;

+ (NSString*)getFilename:(NSString*)uuidString;
+ (NSString*)getDataFilename:(NSString*)uuidString;
+ (NSString*)getFilenameWithUUIDRef:(CFUUIDRef)uuidRef;
+ (NSString*)getDataFilenameWithUUIDRef:(CFUUIDRef)uuidRef;
+ (void) deleteFile:(NSString*)path;
+ (BOOL) isDataFile:(NSString*)path;

@end

static NSString *datExtension = @"dat";

@implementation MSWrapperExceptionManager : NSObject

+ (NSString*)directoryPath {
  static NSString* directoryPath = nil;

  if (!directoryPath) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    directoryPath = [documentsDirectory stringByAppendingPathComponent:@"wrapper_exceptions"];
  }

  return directoryPath;
}

+ (NSString*)getFilename:(NSString*)uuidString {
  return [[self directoryPath] stringByAppendingPathComponent:uuidString];
}

+ (NSString*)getDataFilename:(NSString*)uuidString {
  NSString *filename = [MSWrapperExceptionManager getFilename:uuidString];
  return [filename stringByAppendingPathExtension:datExtension];
}

+ (NSString*)getFilenameWithUUIDRef:(CFUUIDRef)uuidRef {
  NSString *uuidString = [NSString stringWithFormat:@"%@", CFUUIDCreateString(nil, uuidRef)];
  return [MSWrapperExceptionManager getFilename:uuidString];
}

+ (NSString*)getDataFilenameWithUUIDRef:(CFUUIDRef)uuidRef {
  NSString *uuidString = [NSString stringWithFormat:@"%@", CFUUIDCreateString(nil, uuidRef)];
  return [MSWrapperExceptionManager getDataFilename:uuidString];
}

+ (BOOL) isDataFile:(NSString*)path {
  return [path hasSuffix:[@"" stringByAppendingPathExtension:datExtension]];
}

#pragma mark - Public methods

+ (BOOL)hasException {
  return [[self sharedInstance] hasException];
}

+ (void)setWrapperException:(MSException *)wrapperException {
  [self sharedInstance].wrapperException = wrapperException;
}

+ (void)setWrapperExceptionData:(NSData *)wrapperExceptionData {
  [self sharedInstance].wrapperExceptionData = wrapperExceptionData;
}

+ (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef {
  [[self sharedInstance] saveWrapperExceptionData:uuidRef];
}

+ (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  return [[self sharedInstance] loadWrapperExceptionDataWithUUIDString:uuidString];
}

+ (MSException*)loadWrapperException:(CFUUIDRef)uuidRef {
  return [[self sharedInstance] loadWrapperException:uuidRef];
}

+ (void)saveWrapperException:(CFUUIDRef)uuidRef {
  [[self sharedInstance] saveWrapperException:uuidRef];
}

+ (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  [[self sharedInstance] deleteWrapperExceptionWithUUID:uuidRef];
}

+ (void)deleteAllWrapperExceptions {
  [[self sharedInstance] deleteAllWrapperExceptions];
}

+ (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString {
  [[self sharedInstance] deleteWrapperExceptionDataWithUUIDString:uuidString];
}
+ (void)deleteAllWrapperExceptionData {
  [[self sharedInstance] deleteAllWrapperExceptionData];
}

#pragma mark - Private methods

- (instancetype)init {
  if ((self = [super init])) {

    _wrapperException = nil;
    _wrapperExceptionData = [[NSMutableDictionary alloc] init];

    // Create the directory if it doesn't exist
    NSFileManager *defaultManager = [NSFileManager defaultManager];

    NSString *directoryPath = [MSWrapperExceptionManager directoryPath];

    if (![defaultManager fileExistsAtPath:directoryPath]) {
      NSError *error = nil;
      [defaultManager createDirectoryAtPath:directoryPath
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error];
      if (error) {
        MSLogError([MSCrashes getLoggerTag], @"Error creating directory %@: %@",
                   directoryPath, error.localizedDescription);
      }
    }
  }
  
  return self;
}

+ (instancetype)sharedInstance {
  static MSWrapperExceptionManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (BOOL)hasException {
  return _wrapperException != nil;
}

- (MSException*)loadWrapperException:(CFUUIDRef)uuidRef {

  if (_wrapperException != nil && CFEqual(CFUUIDCreateString(nil, _currentUUIDRef), CFUUIDCreateString(nil, uuidRef))) {
    return _wrapperException;
  }

  NSString *filename = [MSWrapperExceptionManager getFilenameWithUUIDRef:uuidRef];
  MSException *loadedException = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];

  if (loadedException == nil) {
    MSLogError([MSCrashes getLoggerTag], @"Could not load wrapper exception from file %@", filename);
    return nil;
  }

  _wrapperException = loadedException;
  _currentUUIDRef = uuidRef;

  return _wrapperException;
}


- (void)saveWrapperException:(CFUUIDRef)uuidRef {
  NSString *filename = [MSWrapperExceptionManager getFilenameWithUUIDRef:uuidRef];
  BOOL success = [NSKeyedArchiver archiveRootObject:_wrapperException toFile:filename];
  if (!success) {
    MSLogError([MSCrashes getLoggerTag], @"Error saving file %@", filename);
  }
}

- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  NSString *path = [MSWrapperExceptionManager getFilenameWithUUIDRef:uuidRef];
  [MSWrapperExceptionManager deleteFile:path];
}

- (void)deleteAllWrapperExceptions {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *directoryPath = [MSWrapperExceptionManager directoryPath];

  for (NSString *filePath in [fileManager enumeratorAtPath:directoryPath]) {
    if (![MSWrapperExceptionManager isDataFile:filePath]) {
      NSString *path = [directoryPath stringByAppendingPathComponent:filePath];
      [MSWrapperExceptionManager deleteFile:path];
    }
  }
}

- (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef {
  NSString* dataFilename = [MSWrapperExceptionManager getDataFilenameWithUUIDRef:uuidRef];
  [_wrapperExceptionData writeToFile:dataFilename atomically:YES];
}

- (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString {

  //TODO first, check if it's in our dictionary
  NSString* dataFilename = [MSWrapperExceptionManager getDataFilename:uuidString];

  NSData *data = [_wrapperExceptionData objectForKey:dataFilename];
  if (data) {
    return data;
  }

  NSError *error = nil;
  data = [NSData dataWithContentsOfFile:dataFilename options:NSDataReadingMappedIfSafe error:&error];
  if (error) {
    MSLogError([MSCrashes getLoggerTag], @"Error loading file %@: %@",
               dataFilename, error.localizedDescription);
  }

  return data;
}

- (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString {

  NSString* dataFilename = [MSWrapperExceptionManager getDataFilename:uuidString];

  //TODO must save data to dictionary first
  NSData *data = [self loadWrapperExceptionDataWithUUIDString:uuidString];
  [_wrapperExceptionData setObject:data forKey:dataFilename];
  [MSWrapperExceptionManager deleteFile:dataFilename];
}

- (void)deleteAllWrapperExceptionData {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *directoryPath = [MSWrapperExceptionManager directoryPath];
  for (NSString *filePath in [fileManager enumeratorAtPath:directoryPath]) {
    if ([MSWrapperExceptionManager isDataFile:filePath]) {
      NSString *path = [directoryPath stringByAppendingPathComponent:filePath];
      [MSWrapperExceptionManager deleteFile:path];
    }
  }
}

+ (void)deleteFile:(NSString*)path {
  NSError *error = nil;
  [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
  if (error) {
    MSLogError([MSCrashes getLoggerTag], @"Error deleting file %@: %@",
               path, error.localizedDescription);
  }

}

@end
