/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSWrapperExceptionManager.h"

@interface MSWrapperExceptionManager ()

@property MSException *wrapperException;
@property NSMutableDictionary *wrapperExceptionData;
@property NSData *unsavedWrapperExceptionData;
@property CFUUIDRef currentUUIDRef;
@property(weak, nonatomic) id <MSWrapperCrashesInitializationDelegate> crashesDelegate;

@property(class, copy, readonly) NSString *dataFileExtension;
@property(class, copy, readonly) NSString *directoryName;
@property(class, copy, readonly) NSString *directoryPath;

+ (MSWrapperExceptionManager *)sharedInstance;

- (BOOL)hasException;

- (MSException *)loadWrapperException:(CFUUIDRef)uuidRef;

- (void)saveWrapperException:(CFUUIDRef)uuidRef;

- (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;

- (void)deleteAllWrapperExceptions;

- (void)deleteAllWrapperExceptionData;

- (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef;

- (NSData *)loadWrapperExceptionDataWithUUIDString:(NSString *)uuidString;

- (void)deleteWrapperExceptionDataWithUUIDString:(NSString *)uuidString;

+ (NSString *)directoryPath;

+ (NSString *)getFilename:(NSString *)uuidString;

+ (NSString *)getDataFilename:(NSString *)uuidString;

+ (NSString *)getFilenameWithUUIDRef:(CFUUIDRef)uuidRef;

+ (NSString *)getDataFilenameWithUUIDRef:(CFUUIDRef)uuidRef;

+ (void)deleteFile:(NSString *)path;

+ (BOOL)isDataFile:(NSString *)path;

+ (NSString *)uuidRefToString:(CFUUIDRef)uuidRef;

+ (BOOL)isCurrentUUIDRef:(CFUUIDRef)uuidRef;

- (void)startCrashReportingFromWrapperSdk;

@end
