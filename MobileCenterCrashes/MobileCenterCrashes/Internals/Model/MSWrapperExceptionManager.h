/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class MSException;

@interface MSWrapperExceptionManager : NSObject

+(void)setWrapperException:(MSException*)exception;

+(MSException*)getWrapperException;

+(void)loadWrapperException:(CFUUIDRef)uuidRef;

+(void)saveWrapperException:(CFUUIDRef)uuidRef;

+(void)deleteWrapperExceptionWithUUID:(CFUUIDRef)uuidRef;

+(void)deleteAllWrapperExceptions;

+(BOOL)hasException;

+(NSString*)getFilename:(CFUUIDRef)uuidRef;

@end
