#import <Foundation/Foundation.h>

@protocol MSDatabaseConnection <NSObject>

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename;

-(BOOL)executeQuery:(NSString *)query;
-(NSArray<NSString*> *)loadDataFromDB:(NSString *)query;

@end
