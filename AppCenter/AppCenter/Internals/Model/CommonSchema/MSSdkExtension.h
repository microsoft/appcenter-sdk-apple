#import <Foundation/Foundation.h>

@interface MSSdkExtension : NSObject

@property(nonatomic, copy) NSString *ver;
@property(nonatomic, copy) NSString *epoch;
@property(nonatomic) int64_t seq;
@property(nonatomic, copy) NSString *installId;

@end
