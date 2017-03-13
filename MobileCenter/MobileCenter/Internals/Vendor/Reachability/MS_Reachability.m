/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import <CoreFoundation/CoreFoundation.h>

#import "MS_Reachability.h"

#pragma mark IPv6 Support

NSString *kMSReachabilityChangedNotification = @"kMSNetworkReachabilityChangedNotification";

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 0

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char *comment) {
#if kShouldPrintReachabilityFlags

  NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n", (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
        (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',

        (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
        (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
        (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
        (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-', comment);
#endif
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
#pragma unused(target, flags)
  NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
  NSCAssert([(__bridge NSObject *)info isKindOfClass:[MS_Reachability class]],
            @"info was wrong class in ReachabilityCallback");

  MS_Reachability *noteObject = (__bridge MS_Reachability *)info;
  // Post a notification to notify the client that the network reachability changed.
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:noteObject];
}

#pragma mark - Reachability extension

@interface MS_Reachability ()

@property(nonatomic) SCNetworkReachabilityRef reachabilityRef;

@end

#pragma mark - Reachability implementation

/**
 * Instantiation, deallocation and starting/stopping notifier for reachability instance are enforced to run in a same thread
 * during the life cycle of reachability instance. MS_Reachability is not thread-safe so stopNotifier doesn't properly
 * unschedule jobs from the loop when it is called from a different thread, and this generates unexpected crashes
 * that are caused by accessing a disposed instance especially when reachability is used for local variables.
 */
@implementation MS_Reachability {
}

/**
 * Get a queue for MS_Reachability.
 *
 * @return A queue for MS_Reachability.
 */
+ (dispatch_queue_t)notifierQueue {
  static dispatch_queue_t notifierQueue = nil;
  if (!notifierQueue) {
    notifierQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
  }
  return notifierQueue;
}

// It's based on Apple's sample code. Disable an one warning type for this function
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
  __block MS_Reachability *returnValue = NULL;
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
  if (reachability != NULL) {
    dispatch_sync([MS_Reachability notifierQueue], ^{
      returnValue = [[self alloc] init];
    });
    if (returnValue != NULL) {
      returnValue.reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

#pragma clang diagnostic pop

+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress {
  __block MS_Reachability *returnValue = NULL;
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);
  if (reachability != NULL) {
    dispatch_sync([MS_Reachability notifierQueue], ^{
      returnValue = [[self alloc] init];
    });
    if (returnValue != NULL) {
      returnValue.reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

+ (instancetype)reachabilityForInternetConnection {
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;

  return [self reachabilityWithAddress:(const struct sockaddr *)&zeroAddress];
}

#pragma mark reachabilityForLocalWiFi
// reachabilityForLocalWiFi has been removed from the sample.  See ReadMe.md for more information.
//+ (instancetype)reachabilityForLocalWiFi

#pragma mark - Start and stop notifier

- (BOOL)startNotifier {
  __block BOOL returnValue = NO;
  dispatch_sync([MS_Reachability notifierQueue], ^{
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, ReachabilityCallback, &context)) {
      if (SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(),
                                                   kCFRunLoopDefaultMode)) {
        returnValue = YES;
      }
    }
  });
  return returnValue;
}

- (void)stopNotifier {
  dispatch_sync([MS_Reachability notifierQueue], ^{
    if (self.reachabilityRef != NULL) {
      SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
  });
}

- (void)dealloc {
  [self stopNotifier];
  if (self.reachabilityRef != NULL) {
    CFRelease(self.reachabilityRef);
  }
}

#pragma mark - Network Flag Handling

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
  PrintReachabilityFlags(flags, "networkStatusForFlags");
  if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
    // The target host is not reachable.
    return NotReachable;
  }

  NetworkStatus returnValue = NotReachable;

  if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
    /*
     If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
     */
    returnValue = ReachableViaWiFi;
  }

  if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
       (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
    /*
     ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or
     higher APIs...
     */

    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
      /*
       ... and no [user] intervention is needed...
       */
      returnValue = ReachableViaWiFi;
    }
  }

  if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
    /*
     ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
     */
    returnValue = ReachableViaWWAN;
  }

  return returnValue;
}

- (BOOL)connectionRequired {
  NSAssert(self.reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
    return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
  }

  return NO;
}

- (NetworkStatus)currentReachabilityStatus {
  NSAssert(self.reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
  NetworkStatus returnValue = NotReachable;
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
    returnValue = [self networkStatusForFlags:flags];
  }

  return returnValue;
}

@end
