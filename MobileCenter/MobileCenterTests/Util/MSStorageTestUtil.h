#import "MSFile.h"
#import <Foundation/Foundation.h>

@interface MSStorageTestUtil : NSObject

+ (NSString *)logsDir;
+ (NSString *)storageDirForGroupId:(NSString *)groupId;
+ (NSString *)filePathForLogWithId:(NSString *)logsId extension:(NSString *)extension groupId:(NSString *)groupId;
+ (MSFile *)createFileWithId:(NSString *)logsId
                        data:(NSData *)data
                   extension:(NSString *)extension
                     groupId:(NSString *)groupId
                creationDate:(NSDate *)creationDate;
+ (void)createDirectoryAtPath:(NSString *)directoryPath;
+ (void)resetLogsDirectory;

@end
