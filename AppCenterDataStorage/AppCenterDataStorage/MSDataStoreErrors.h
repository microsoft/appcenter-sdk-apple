#import <Foundation/Foundation.h>
#import "MSAppCenterErrors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

static NSString *const kMSACDataStoreErrorDomain = MS_APP_CENTER_BASE_DOMAIN  @"DataStoreErrorDomain";

#pragma mark - Error Codes

// Error codes
NS_ENUM(NSInteger){kMSACDocumentSerializationErrorCode = 1, kMSACDocumentDeserializationErrorCode = 2};
  
  // Error descriptions
  static NSString const *kMSACDocumentSerializationErrorCodeDesc = @"Document serialization implementation is missing.";
  static NSString const *kMSACDocumentDeserializationErrorCodeDesc = @"Document deserialization implementation is missing.";
  
NS_ASSUME_NONNULL_END
