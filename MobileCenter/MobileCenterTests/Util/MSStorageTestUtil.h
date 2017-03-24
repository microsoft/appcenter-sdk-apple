#import "MSFile.h"
#import <Foundation/Foundation.h>

@interface MSStorageTestUtil : NSObject

+ (NSString *)logsDir;
+ (NSString *)storageDirForGroupID:(NSString *)groupID;
+ (NSString *)filePathForLogWithId:(NSString *)logsId extension:(NSString *)extension groupID:(NSString *)groupID;
+ (MSFile *)createFileWithId:(NSString *)logsId
                        data:(NSData *)data
                   extension:(NSString *)extension
                     groupID:(NSString *)groupID
                creationDate:(NSDate *)creationDate;
+ (void)createDirectoryAtPath:(NSString *)directoryPath;
+ (void)resetLogsDirectory;

@end
