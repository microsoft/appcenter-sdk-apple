@import Foundation;
@import OHHTTPStubs.OHHTTPStubs;

@interface MSHttpTestUtil : NSObject

+ (void)stubHttp500Response;
+ (void)stubHttp404Response;
+ (void)stubHttp200Response;
+ (void)stubNetworkDownResponse;
+ (void)stubLongTimeOutResponse;

@end
