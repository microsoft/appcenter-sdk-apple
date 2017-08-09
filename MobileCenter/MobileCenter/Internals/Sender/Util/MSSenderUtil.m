#import "MSSenderUtil.h"

@implementation MSSenderUtil

+ (BOOL)isRecoverableError:(NSInteger)statusCode {
  return statusCode >= 500 || statusCode == 408 || statusCode == 429;
}

+ (NSInteger)getStatusCode:(NSURLResponse *)response {
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  return httpResponse.statusCode;
}

+ (BOOL)isNoInternetConnectionError:(NSError *)error {
  return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorNotConnectedToInternet));
}

+ (BOOL)isSSLConnectionError:(NSError *)error {
  
  // Check for error domain and if the error.code falls in the range of SSL connection errors (between -2000 and -1200).
  return ([error.domain isEqualToString:NSURLErrorDomain] &&
          ((error.code >= NSURLErrorCannotLoadFromNetwork) && (error.code <= NSURLErrorSecureConnectionFailed)));
}

+ (BOOL)isRequestCanceledError:(NSError *)error {
  return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorCancelled));
}

+ (NSString *)hideSecret:(NSString *)secret {

  // Hide everything if secret is shorter than the max number of displayed characters.
  NSUInteger appSecretHiddenPartLength =
      (secret.length > kMSMaxCharactersDisplayedForAppSecret ? secret.length - kMSMaxCharactersDisplayedForAppSecret
                                                             : secret.length);
  NSString *appSecretHiddenPart =
      [@"" stringByPaddingToLength:appSecretHiddenPartLength withString:kMSHidingStringForAppSecret startingAtIndex:0];
  return [secret stringByReplacingCharactersInRange:NSMakeRange(0, appSecretHiddenPart.length)
                                         withString:appSecretHiddenPart];
}

@end
