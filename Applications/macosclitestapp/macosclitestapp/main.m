//
//  main.m
//  macosclitestapp
//
//  Created by Jacob Wallraff on 5/28/19.
//  Copyright © 2019 Jacob Wallraff. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>
#import "Input.h"

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    while (YES) {
    NSLog(@"Enter your command: ");
    NSString *input = [Input getUserInput];
    if ([input isEqualToString:@"e"]) {
      return 0;
    } else if ([input isEqualToString:@"s"]) {
      [MSAppCenter setLogLevel:MSLogLevelVerbose];
      [MSAppCenter start:@"faa795b0-f640-41ca-a6ad-eed0770111c2" withServices:@[[MSAnalytics class], [MSCrashes class]]];
      if ([MSCrashes hasCrashedInLastSession]) {
        MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
        NSLog(@"We crashed with Signal: %@", errorReport.signal);
        MSDevice *device = [errorReport device];
        NSString *osVersion = [device osVersion];
        NSString *appVersion = [device appVersion];
        NSString *appBuild = [device appBuild];
        NSLog(@"OS Version is: %@", osVersion);
        NSLog(@"App Version is: %@", appVersion);
        NSLog(@"App Build is: %@", appBuild);
      }
    } else if ([input isEqualToString:@"c"]) {
      NSArray *array = [NSArray arrayWithObjects:@1, @2, @3, nil];
      NSLog(@"%@", [array objectAtIndex:4]);
    } else if ([input isEqualToString:@"a"]) {
      [MSAnalytics trackEvent:@"cli-test"];
    } else {
      NSLog(input);
    }
  }
  }
  return 0;
}
