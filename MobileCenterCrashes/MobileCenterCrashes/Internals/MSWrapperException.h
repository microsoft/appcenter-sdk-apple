#import <Foundation/Foundation.h>

@class MSException;

@interface MSWrapperException : NSObject

@property(nonatomic, weak) MSException* exception;
@property(nonatomic, weak) NSData* exceptionData;
@property(nonatomic, copy) NSString* uuid;

// TODO can be internal
- (void) saveToPath:(NSString*)path;
- (void) deleteFromPath:(NSString*)path;


@end
