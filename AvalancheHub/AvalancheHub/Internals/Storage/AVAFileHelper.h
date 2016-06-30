/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 A class which abstracts file i/o operations.
 */
@interface AVAFileHelper : NSObject

/**
 * Sets a custom `NSFileManager` instance. By default, the `defaultManager` will
 * be used.
 *
 * @param fileManager the `NSFileManager` instance to use
 */
+ (void)setFileManager:(NSFileManager *)fileManager;

/**
 * Appends data to a file with the given file name.
 *
 * @param data the data that should be written to disk
 * @param filePath the absolute path to the file
 *
 * @return true if writing data to the given file was succesful
 */
+ (BOOL)appendData:(NSData *)data toFileWithPath:(NSString *)filePath;

/**
 * Delete the file for the given file name.
 *
 * @param filePath the absolute path to the file
 *
 * @return true if deleting the file was succesful
 */
+ (BOOL)deleteFileWithPath:(NSString *)filePath;

/**
 * Returns the content of a file.
 *
 * @param filePath the absolute path to the file
 *
 * @return the content data of the file
 */
+ (NSData *)dataForFileWithPath:(NSString *)filePath;

/**
 * Returns all file names of a given directory.
 *
 * @param directoryPath the absolute path to the directory
 * @param fileExtension a file extension that should be used to filter the
 * results
 *
 * @return the content data of the file
 */
+ (NSArray *)fileNamesForDirectory:(NSString *)directoryPath
                 withFileExtension:(NSString *)fileExtension;

@end
