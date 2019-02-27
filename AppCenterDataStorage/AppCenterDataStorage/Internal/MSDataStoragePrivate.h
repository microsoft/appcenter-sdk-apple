#import "MSDataStorage.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * Base URL for HTTP Distribute update API calls.
 */
static NSString *const kMSDefaultApiUrl = @"https://api.appcenter.ms/v0.1";

@interface MSDataStorage ()

@property(nonatomic, copy) NSString *apiUrl;

@property(nonatomic, copy) MSStorageIngestion *ingestion;

@end

NS_ASSUME_NONNULL_END
