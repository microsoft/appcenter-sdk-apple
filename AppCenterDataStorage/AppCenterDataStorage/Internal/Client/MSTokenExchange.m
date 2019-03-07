#import "AppCenter+Internal.h"
#import "MSDataStorageInternal.h"
#import "MSStorageIngestion.h"
#import "MSTokenExchange.h"
#import "MSTokensResponse.h"
#import "MSTokenResult.h"
#import "MSKeychainUtil.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSPartitions = @"partitions";

@implementation MSTokenExchange : NSObject

+ (void)tokenAsync:(MSStorageIngestion *)httpClient
           partitions:(NSMutableArray *)partitions
    completionHandler:(MSGetTokenAsyncCompletionHandler)completion {
    
    NSMutableArray *tokenArray = [[NSMutableArray alloc] init];
    
    for(NSString *partition in partitions){
        MSTokenResult *result = [MSTokenExchange retrieveCachedToken:partition];
        
        if(result != nil){
            [tokenArray addObject:result];
            [partitions removeObject:partitions];
        }
    }
    
  // Payload.
  NSError *jsonError;
  NSData *payloadData = [NSJSONSerialization dataWithJSONObject:@{kMSPartitions : partitions} options:0 error:&jsonError];

  // Http call.
  [httpClient sendAsync:payloadData
      completionHandler:^(NSString *callId, NSHTTPURLResponse *response, NSData *data, NSError *error) {
        MSLogVerbose([MSDataStorage logTag], @"Get token callback, request Id %@ with status code: %lu", callId,
                     (unsigned long)response.statusCode);

        // If comletion is provided.
        if (completion) {

          // Read tokens.
          NSError *tokenResponsejsonError;
          NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&tokenResponsejsonError];
          if (tokenResponsejsonError) {
            MSLogError([MSDataStorage logTag], @"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]);
            completion([[MSTokensResponse alloc] initWithTokens:nil], error);
          }

          // Create token result object.
          MSTokensResponse *tokens = [[MSTokensResponse alloc] initWithDictionary:jsonDictionary];
          completion(tokens, error);
        }
      }];
}

+ (void)saveToken:(MSTokenResult *)tokenResult {
    NSString *tokenString = [tokenResult serializeToString];
    BOOL success = [MSKeychainUtil storeString:tokenString forKey:tokenResult.partition];
    if (success) {
        MSLogDebug([MSDataStorage logTag], @"Saved token in keychain for the partitionKey : %@.", tokenResult.partition);
    } else {
        MSLogWarning([MSDataStorage logTag], @"Failed to save the token in keychain for the partitionKey : %@.", tokenResult.partition);
    }
}

+ (MSTokenResult *)retrieveCachedToken:(NSString *)partitionName {
    NSString *tokenString = [MSKeychainUtil stringForKey:partitionName];
    
    MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
    
    if(tokenResult != nil){
        
        NSDate *currentUTCDate = [NSDate date];
        
        NSDateFormatter* utcFormatter = [[NSDateFormatter alloc] init];
        [utcFormatter setDateFormat:@"yyyy.MM.dd'T'HH:mmZ"];
        NSDate *tokenExpireDate = [[NSDate alloc]init];
        tokenExpireDate = [utcFormatter dateFromString:tokenResult.expiresOn];
        
        if([currentUTCDate laterDate:tokenExpireDate] == currentUTCDate){
            [self removeCachedToken:partitionName];
            return nil;
        }
        
        MSLogDebug([MSDataStorage logTag], @"Retrieved token from keychain for the partitionKey : %@.", partitionName);
    } else {
        MSLogWarning([MSDataStorage logTag], @"Failed to retrieve token from keychain or none was found for the partitionKey : %@.", partitionName);
    }
    
    return tokenResult;
}

+ (void)removeCachedToken:(NSString *)partitionName {
    NSString *tokenString = [MSKeychainUtil deleteStringForKey:partitionName];
    if (tokenString) {
        MSLogDebug([MSDataStorage logTag], @"Removed token from keychain for the partitionKey : %@.", partitionName);
    } else {
        MSLogWarning([MSDataStorage logTag], @"Failed to remove token from keychain or none was found for the partitionKey : %@.", partitionName);
    }
}

/*- (void)removeAllCachedTokens {
    NSString *authToken = [MSKeychainUtil deleteStringForKey:kMSIdentityAuthTokenKey];
    if (authToken) {
        MSLogDebug([MSDataStorage logTag], @"Removed all the tokens from keychain.");
    } else {
        MSLogWarning([MSDataStorage logTag], @"Failed to remove all of the tokens from keychain");
    }
}*/

@end

NS_ASSUME_NONNULL_END
