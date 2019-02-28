#import "MSTokenExchange.h"
#import "MSStorageIngestion.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSPartitions = @"partitions";

@implementation MSTokenExchange : NSObject

+ (void)tokenAsync:(MSStorageIngestion *)httpClient
           partitions:(NSArray *)partitions
    completionHandler:(MSGetTokenAsyncCompletionHandler)completion {

  // Payload
  NSError *jsonError;
  NSData *payloadData = [NSJSONSerialization dataWithJSONObject:@{kMSPartitions : partitions} options:0 error:&jsonError];

  [httpClient sendAsync:payloadData
      completionHandler:^(NSString *callId, NSUInteger statusCode, NSData *data, NSError *error) {
        NSLog(@"Get token callback, request Id %@ with status code: %lu", callId, (unsigned long)statusCode);

        completion(data, error);
      }];
}

@end

NS_ASSUME_NONNULL_END
