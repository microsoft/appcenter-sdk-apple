#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Domain

extern NSString *const kMSUDErrorDomain;

#pragma mark - Update API token

// Error codes
NS_ENUM(NSInteger){kMSUDUpdateTokenURLInvalidErrorCode = 1, kMSUDUpdateTokenSchemeNotFoundErrorCode = 2};
  
// Error descriptions
extern NSString const *kMSUDUpdateTokenURLInvalidErrorDesc;
extern NSString const *kMSUDUpdateTokenSchemeNotFoundErrorDesc;

NS_ASSUME_NONNULL_END
