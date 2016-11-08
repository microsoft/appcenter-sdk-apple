/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperExceptionManager.h"
#import "MSCrashes.h"
#import "MSException.h"

@implementation MSWrapperExceptionManager : NSObject

static MSException *wrapperException;
static NSString *directoryPath;

+(void)initialize
{
  [super initialize];
  
  wrapperException = nil;
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  directoryPath = [documentsDirectory stringByAppendingPathComponent:@"wrapper_exceptions"];
  
  // Create the directory if it doesn't exist
  BOOL isDir = YES;
  if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:nil];
  }
}

+(MSException*)getWrapperException
{
  return wrapperException;
}

+(void)setWrapperException:(MSException*)exception
{
  wrapperException = exception;
}

+(BOOL)hasException
{
  return wrapperException != nil;
}

+(NSString*)getFilename:(CFUUIDRef)uuidRef
{
  NSString *uuidString = [NSString stringWithFormat:@"%@", CFUUIDCreateString(NULL, uuidRef)];
  return [directoryPath stringByAppendingPathComponent:uuidString];
}

+(void)loadWrapperException:(CFUUIDRef)uuidRef
{
  NSString* filename = [MSWrapperExceptionManager getFilename:uuidRef];
  wrapperException = [NSKeyedUnarchiver unarchiveObjectWithFile:filename];
}

+(void)saveWrapperException:(CFUUIDRef)uuidRef
{
  NSString* filename = [MSWrapperExceptionManager getFilename:uuidRef];
  [NSKeyedArchiver archiveRootObject:wrapperException toFile:filename];
}

+(void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef
{
  NSError *error = [[NSError alloc] init];
  NSString* path = [MSWrapperExceptionManager getFilename:uuidRef];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:path error:&error];
}

+(void)deleteAllWrapperExceptions
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSError *error = [[NSError alloc] init];
  for (NSString *filePath in [fileManager enumeratorAtPath:directoryPath]) {
    NSString *path = [directoryPath stringByAppendingPathComponent:filePath];
    [fileManager removeItemAtPath:path error:&error];
  }
}

@end
