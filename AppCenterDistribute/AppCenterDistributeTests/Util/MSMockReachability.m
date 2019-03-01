#import "MSMockReachability.h"
#import "MSTestFrameworks.h"

static NSString *kMSNetworkReachabilityChangedNotificationName = @"kMSNetworkReachabilityChangedNotification";

NetworkStatus currentNetworkStatus;

@interface MSMockReachability ()

@end

@implementation MSMockReachability

+ (void)setCurrentNetworkStatus: (NetworkStatus)networkStatus {
  currentNetworkStatus = networkStatus;
}

+ (id)startMocking {
  id mockReachability = OCMClassMock([MS_Reachability class]);
  OCMStub([mockReachability reachabilityForInternetConnection]).andReturn(mockReachability);
  OCMStub([mockReachability currentReachabilityStatus]).andDo(^(NSInvocation *invocation) {
    NetworkStatus status = currentNetworkStatus;
    [invocation setReturnValue:&status];
  });
  OCMStub([mockReachability startNotifier]).andDo(^(__unused NSInvocation *invocation) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMSNetworkReachabilityChangedNotificationName
                                                        object:mockReachability];
  });
  return mockReachability;
}

@end
