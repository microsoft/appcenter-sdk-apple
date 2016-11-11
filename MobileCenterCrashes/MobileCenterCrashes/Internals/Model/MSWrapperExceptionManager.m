/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperExceptionManager.h"
#import "MSCrashes.h"
#import "MSException.h"
#import "MSCrashesInternal.h"

@interface MSWrapperExceptionManager ()

@property MSException *wrapperException;
@property CFUUIDRef currentUUIDRef;

+ (MSWrapperExceptionManager*)sharedInstance;
- (BOOL)hasException;
- (MSException*)loadWrapperException:(CFUUIDRef)uuidRef;
- (void)saveWrapperException:(CFUUIDRef)uuidRef;
- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;
- (void)deleteAllWrapperExceptions;
+ (NSString*)directoryPath;
+ (NSString*)getFilename:(CFUUIDRef)uuidRef;

@end

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

+ (NSString*)getFilename:(CFUUIDRef)uuidRef {
  NSString *uuidString = [NSString stringWithFormat:@"%@", CFUUIDCreateString(nil, uuidRef)];
  return [[self directoryPath] stringByAppendingPathComponent:uuidString];
}

#pragma mark - Public methods

+ (BOOL)hasException {
  return [[self sharedInstance] hasException];
}

+ (void)setWrapperException:(MSException *)wrapperException {
  [self sharedInstance].wrapperException = wrapperException;
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

#pragma mark - Private methods

- (instancetype)init {
  if ((self = [super init])) {

    _wrapperException = nil;


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

  NSString *filename = [MSWrapperExceptionManager getFilename:uuidRef];
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
  NSString *filename = [MSWrapperExceptionManager getFilename:uuidRef];
  BOOL success = [NSKeyedArchiver archiveRootObject:_wrapperException toFile:filename];
  if (!success) {
    MSLogError([MSCrashes getLoggerTag], @"Error saving file %@", filename);
  }
}

- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef {
  NSError *error = nil;
  NSString *path = [MSWrapperExceptionManager getFilename:uuidRef];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:path error:&error];
  if (error) {
    MSLogError([MSCrashes getLoggerTag], @"Error deleting file %@: %@",
               path, error.localizedDescription);
  }
}

- (void)deleteAllWrapperExceptions {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSString *directoryPath = [MSWrapperExceptionManager directoryPath];
  for (NSString *filePath in [fileManager enumeratorAtPath:directoryPath]) {
    NSString *path = [directoryPath stringByAppendingPathComponent:filePath];
    [fileManager removeItemAtPath:path error:&error];
    if (error) {
      MSLogError([MSCrashes getLoggerTag], @"Error deleting file %@: %@",
                 path, error.localizedDescription);
    }
  }
}

@end
