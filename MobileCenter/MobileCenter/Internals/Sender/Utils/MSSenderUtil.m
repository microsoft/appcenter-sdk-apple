#import "MSSenderUtil.h"

@implementation MSSenderUtil

+ (BOOL)isRecoverableError:(NSInteger)statusCode {
  return statusCode >= 500 || statusCode == 408 || statusCode == 429 || statusCode == 401;
}

+ (NSInteger)getStatusCode:(NSURLResponse *)response {
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  return httpResponse.statusCode;
}

+ (BOOL)isNoInternetConnectionError:(NSError *)error {
  return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorNotConnectedToInternet));
}

+ (BOOL)isRequestCanceledError:(NSError *)error {
  return ([error.domain isEqualToString:NSURLErrorDomain] && (error.code == NSURLErrorCancelled));
}

@end
