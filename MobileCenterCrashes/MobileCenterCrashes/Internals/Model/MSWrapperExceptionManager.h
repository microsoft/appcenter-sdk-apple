/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class MSException;

@interface MSWrapperExceptionManager : NSObject

+ (BOOL)hasException;

+ (MSException*)loadWrapperException:(CFUUIDRef)uuidRef;

+ (void)saveWrapperException:(CFUUIDRef)uuidRef;

+ (void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;

+ (void)deleteAllWrapperExceptions;

+ (void)setWrapperException:(MSException*)exception;

+ (void)setWrapperExceptionData:(NSData *)wrapperExceptionData;
+ (void)saveWrapperExceptionData:(CFUUIDRef)uuidRef;

+ (NSData*)loadWrapperExceptionDataWithUUIDString:(NSString*)uuidString;
+ (void)deleteWrapperExceptionDataWithUUIDString:(NSString*)uuidString;
+ (void)deleteAllWrapperExceptionData;

@end
