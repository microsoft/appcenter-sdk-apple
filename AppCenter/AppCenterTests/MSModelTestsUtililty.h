#import "MSAbstractLogInternal.h"
#import "MSDevice.h"
#import <Foundation/Foundation.h>

@interface MSModelTestsUtililty : NSObject

/**
 * Get dummy values for device model.
 * @return Dummy values for device model.
 */
+ (NSDictionary *)deviceDummies;

+ (NSMutableDictionary *)extensionDummies;

+ (NSDictionary *)userExtensionDummies;

+ (NSDictionary *)locExtensionDummies;

+ (NSDictionary *)osExtensionDummies;

+ (NSDictionary *)appExtensionDummies;

+ (NSDictionary *)protocolExtensionDummies;

+ (NSDictionary *)netExtensionDummies;

+ (NSMutableDictionary *)sdkExtensionDummies;

+ (NSDictionary *)dataDummies;


/**
 * Get a dummy device model.
 * @return A dummy device model.
 */
+ (MSDevice *)dummyDevice;

/**
 * Get dummy values for abstract log.
 * @return Dummy values for abstract log.
 */
+ (NSDictionary *)abstractLogDummies;

+ (MSCSExtensions *)extensionsWithDummyValues:(NSDictionary *)dummyValues ;

+ (MSUserExtension *)userExtensionWithDummyValues:(NSDictionary *)dummyValues ;

+ (MSLocExtension *)locExtensionWithDummyValues:(NSDictionary *)dummyValues ;

+ (MSOSExtension *)osExtensionWithDummyValues:(NSDictionary *)dummyValues;

+ (MSAppExtension *)appExtensionWithDummyValues:(NSDictionary *)dummyValues;

+ (MSProtocolExtension *)protocolExtensionWithDummyValues:(NSDictionary *)dummyValues;

+ (MSNetExtension *)netExtensionWithDummyValues:(NSDictionary *)dummyValues;

+ (MSSDKExtension *)sdkExtensionWithDummyValues:(NSDictionary *)dummyValues;

+ (MSCSData *)dataWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate an abstract log with dummy values.
 * @param log An abstract log to be filled with dummy values.
 */
+ (void)populateAbstractLogWithDummies:(MSAbstractLog *)log;

@end
