#import <Foundation/Foundation.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface MSHttpTestUtil : NSObject

+(void)stubHttp500Response;
+(void)stubHttp200Response;
+(void)stubNetworkDownResponse;
+(void)stubLongTimeOutResponse;

@end
