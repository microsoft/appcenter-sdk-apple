#import "MSUtility+DisableSettings.h"
#import "MSServiceInternal.h"

@implementation MSUtility (MSDisableSettings)

/**
 * Determines whether a service should be disabled.
 *
 * @param serviceName The service name to consider for disabling.
 *
 * @return YES if the service should be disabled.
 */
+ (BOOL)shouldDisable:(NSString*)serviceName {
  NSDictionary *environmentVariables = [[NSProcessInfo processInfo] environment];
  NSString *disabledServices = environmentVariables[@"APP_CENTER_DISABLE"];
  if (!disabledServices) {
    return NO;
  }
  NSArray* disabledServicesList = [disabledServices componentsSeparatedByString:@","];
  return  [disabledServicesList containsObject:serviceName] ||
          [disabledServicesList containsObject:@"All"];
}

@end
