#import "MSTokenExchange.h"
#import "AppCenter+Internal.h"
#import "MSDataStoreInternal.h"
#import "MSStorageIngestion.h"
#import "MSTokensResponse.h"
#import "MSTokenResult.h"
#import "MSKeychainUtil.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kMSPartitions = @"partitions";
static NSString *const kMSStorageReadOnlyDbTokenKey = @"MSStorageReadOnlyDbToken";
static NSString *const kMSStorageUserDbTokenKey = @"MSStorageUserDbToken";

@implementation MSTokenExchange : NSObject

+ (void)performDbTokenAsyncOperationWithHttpClient:(MSStorageIngestion *)httpClient
           partition:(NSString *)partition
    completionHandler:(MSGetTokenAsyncCompletionHandler)completion {
    
    MSTokenResult *cachedToken = [MSTokenExchange retrieveCachedToken:partition];
    
    if(cachedToken == nil)
    {   
        // Payload.
        NSError *jsonError;
        NSData *payloadData = [NSJSONSerialization dataWithJSONObject:@{kMSPartitions : @[partition]} options:0 error:&jsonError];
        
        // Http call.
        [httpClient sendAsync:payloadData
            completionHandler:^(NSString *callId, NSHTTPURLResponse *response, NSData *data, NSError *error) {
                MSLogVerbose([MSDataStore logTag], @"Get token callback, request Id %@ with status code: %lu", callId,
                             (unsigned long)response.statusCode);
                
                // If completion is provided.
                if (completion) {
                    
                    // Read tokens.
                    NSError *tokenResponsejsonError;
                    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&tokenResponsejsonError];
                    if (tokenResponsejsonError) {
                        MSLogError([MSDataStore logTag], @"Can't deserialize tokens with error: %@", [tokenResponsejsonError description]);
                        completion([[MSTokensResponse alloc] initWithTokens:nil], error);
                    }
                    
                    [MSTokenExchange saveToken:[[MSTokenResult alloc] initWithDictionary:jsonDictionary[kMSTokens][0]]];
                    // Create token result object.
                    MSTokensResponse *tokens = [[MSTokensResponse alloc] initWithDictionary:jsonDictionary];
                    completion(tokens, error);
                }
            }];
    }
    else
    {
        NSError *error;
        completion([[MSTokensResponse alloc] initWithTokens:@[cachedToken]], error);
    }
}

+ (void)saveToken:(MSTokenResult *)tokenResult {
    NSString *tokenString = [tokenResult serializeToString];
    BOOL success = [MSKeychainUtil storeString:tokenString forKey:[MSTokenExchange tokenKeyNameForPartition:tokenResult.partition]];
    if (success) {
        MSLogDebug([MSDataStore logTag], @"Saved token in keychain for the partitionKey : %@.", tokenResult.partition);
    } else {
        MSLogWarning([MSDataStore logTag], @"Failed to save the token in keychain for the partitionKey : %@.", tokenResult.partition);
    }
}

+ (MSTokenResult *)retrieveCachedToken:(NSString *)partitionName {
    NSString *tokenString = [MSKeychainUtil stringForKey:[MSTokenExchange tokenKeyNameForPartition:partitionName]];
    if(tokenString != nil){
        MSTokenResult *tokenResult = [[MSTokenResult alloc] initWithString:tokenString];
        
        if(tokenResult != nil){
            
            NSDate *currentUTCDate = [NSDate date];
            
            NSDateFormatter* utcFormatter = [[NSDateFormatter alloc] init];
            [utcFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            NSDate *tokenExpireDate = [utcFormatter dateFromString:tokenResult.expiresOn];
            
            if([currentUTCDate laterDate:tokenExpireDate] == currentUTCDate){
                [MSTokenExchange removeCachedToken:partitionName];
                
                 MSLogWarning([MSDataStore logTag], @"The token in the cache has expired for the partitionKey : %@.", partitionName);
                return nil;
            }
            
            MSLogDebug([MSDataStore logTag], @"Retrieved token from keychain for the partitionKey : %@.", partitionName);
            return tokenResult;
        }
    }
    
     MSLogWarning([MSDataStore logTag], @"Failed to retrieve token from keychain or none was found for the partitionKey : %@.", partitionName);
    
    return nil;
}

+ (void)removeCachedToken:(NSString *)partitionName {
    NSString *tokenString = [MSKeychainUtil deleteStringForKey:[MSTokenExchange tokenKeyNameForPartition:partitionName]];
    
    if (tokenString) {
        MSLogDebug([MSDataStore logTag], @"Removed token from keychain for the partitionKey : %@.", partitionName);
    } else {
        MSLogWarning([MSDataStore logTag], @"Failed to remove token from keychain or none was found for the partitionKey : %@.", partitionName);
    }
}

+ (void)removeAllCachedTokens {
    NSString *readonlyTokenString = [MSKeychainUtil deleteStringForKey:kMSStorageReadOnlyDbTokenKey];
    NSString *userTokenString = [MSKeychainUtil deleteStringForKey:kMSStorageUserDbTokenKey];
    if (readonlyTokenString && userTokenString) {
        MSLogDebug([MSDataStore logTag], @"Removed all the tokens from keychain.");
    } else {
        MSLogWarning([MSDataStore logTag], @"Failed to remove all of the tokens from keychain");
    }
}

+ (NSString *)tokenKeyNameForPartition:(NSString *)partitionName{
    
    NSString *tokenKeyName = kMSStorageReadOnlyDbTokenKey;
    if(![partitionName containsString:MSDataStoreAppDocumentsPartition])
    {
        tokenKeyName = kMSStorageUserDbTokenKey;
    }
    
    return tokenKeyName;
}

@end

NS_ASSUME_NONNULL_END
