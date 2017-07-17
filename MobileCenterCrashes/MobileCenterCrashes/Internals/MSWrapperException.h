#import <Foundation/Foundation.h>

@class MSException;

@interface MSWrapperException : NSObject 

@property(nonatomic, strong) MSException* exception;
@property(nonatomic, strong) NSData* exceptionData;
@property(nonatomic, copy) NSDate* timestamp;

@end
