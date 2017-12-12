#import <Foundation/Foundation.h>

#import "MSUtility.h"

/*
 * Workaround for exporting symbols from category object files.
 */
extern NSString *MSUtilityEnvironmentCategory;

/**
 *  App environment
 */
typedef NS_ENUM(NSInteger, MSEnvironment) {

  /**
   *  App has been downloaded from the AppStore.
   */
  MSEnvironmentAppStore = 0,

  /**
   *  App has been downloaded from TestFlight.
   */
  MSEnvironmentTestFlight = 1,

  /**
   *  App has been installed by some other mechanism.
   *  This could be Ad-Hoc, Enterprise, etc.
   */
  MSEnvironmentOther = 99
};

/**
 * Utility class that is used throughout the SDK.
 * Environment part.
 */
@interface MSUtility (Environment)

/**
 * Detect the environment that the app is running in.
 *
 * @return the MSEnvironment of the app.
 */
+ (MSEnvironment)currentAppEnvironment;

@end
