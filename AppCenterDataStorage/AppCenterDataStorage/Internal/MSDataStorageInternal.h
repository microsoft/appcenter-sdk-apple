#import <Foundation/Foundation.h>

#import "MSDataStorage.h"
#import "MSStorageIngestion.h"
#import "MSServiceInternal.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDataStorage<T : id<MSSerializableDocument>> () <MSServiceInternal>

/**
 * An API url that is used to get resouce tokens.
 */
@property(nonatomic, copy) NSString *apiUrl;

/**
 * An ingestion instance that is used to send a request for new token exchange service
 */
@property(nonatomic, nullable) MSStorageIngestion *ingestion;

@end

NS_ASSUME_NONNULL_END
