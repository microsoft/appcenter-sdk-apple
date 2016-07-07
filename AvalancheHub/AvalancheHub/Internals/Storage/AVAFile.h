/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A class that represents a file on the file system.
 */
@interface AVAFile : NSObject

/**
 * The creation date of the file.
 */
@property (nonatomic, strong) NSDate *creationDate;

/**
 * The unique identifier for this file.
 */
@property (nonatomic, copy) NSString *fileId;

/**
 * Returns a new `AVAFile` instance with a given file id and creation date.
 *
 * @param fileId a unique file identifier
 * @param creationDate the creation date of the file
 *
 * @return a new `AVAFile` instance
 */
- (instancetype)initWithFileId:(NSString *)fileId creationDate:(NSDate *)creationDate;

@end

NS_ASSUME_NONNULL_END