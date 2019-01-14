#import <Foundation/Foundation.h>

#import "MSAbstractLogInternal.h"
#import "MSDevice.h"

@class MSMetadataExtension;
@class MSUserExtension;
@class MSLocExtension;
@class MSOSExtension;
@class MSAppExtension;
@class MSProtocolExtension;
@class MSNetExtension;
@class MSSDKExtension;
@class MSDeviceExtension;

@interface MSModelTestsUtililty : NSObject

/**
 * Get dummy values for device model.
 *
 * @return Dummy values for device model.
 */
+ (NSDictionary *)deviceDummies;

/**
 * Get dummy values for common schema extensions.
 *
 * @return Dummy values for common schema extensions.
 */
+ (NSMutableDictionary *)extensionDummies;

/**
 * Get dummy values for common schema metadata extensions.
 *
 * @return Dummy values for common schema metadata extensions.
 */
+ (NSDictionary *)metadataExtensionDummies;

/**
 * Get dummy values for common schema user extensions.
 *
 * @return Dummy values for common schema user extensions.
 */
+ (NSDictionary *)userExtensionDummies;

/**
 * Get dummy values for common schema location extensions.
 *
 * @return Dummy values for common schema location extensions.
 */
+ (NSDictionary *)locExtensionDummies;

/**
 * Get dummy values for common schema os extensions.
 *
 * @return Dummy values for common schema os extensions.
 */
+ (NSDictionary *)osExtensionDummies;

/**
 * Get dummy values for common schema app extensions.
 *
 * @return Dummy values for common schema app extensions.
 */
+ (NSDictionary *)appExtensionDummies;

/**
 * Get dummy values for common schema protocol extensions.
 *
 * @return Dummy values for common schema protocol extensions.
 */
+ (NSDictionary *)protocolExtensionDummies;

/**
 * Get dummy values for common schema network extensions.
 *
 * @return Dummy values for common schema network extensions.
 */
+ (NSDictionary *)netExtensionDummies;

/**
 * Get dummy values for common schema sdk extensions.
 *
 * @return Dummy values for common schema sdk extensions.
 */
+ (NSMutableDictionary *)sdkExtensionDummies;

/**
 * Get dummy values for common schema sdk extensions.
 *
 * @return Dummy values for common schema device extensions.
 */
+ (NSMutableDictionary *)deviceExtensionDummies;

/**
 * Get ordered dummy values data, e.g. properties.
 *
 * @return Ordered dummy values data, e.g. properties.
 */
+ (NSDictionary *)orderedDataDummies;

/**
 * Get unordered dummy values data, e.g. properties.
 *
 * @return Unordered dummy values data, e.g. properties.
 */
+ (NSDictionary *)unorderedDataDummies;

/**
 * Get dummy values for abstract log.
 *
 * @return Dummy values for abstract log.
 */
+ (NSDictionary *)abstractLogDummies;

/**
 * Get a dummy device model.
 *
 * @return A dummy device model.
 */
+ (MSDevice *)dummyDevice;

/**
 * Populate dummy common schema extensions.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return The dummy common schema extensions.
 */
+ (MSCSExtensions *)extensionsWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema user extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema user extension.
 */
+ (MSMetadataExtension *)metadataExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema user extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema user extension.
 */
+ (MSUserExtension *)userExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema location extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema location extension.
 */
+ (MSLocExtension *)locExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema os extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema os extension.
 */
+ (MSOSExtension *)osExtensionWithDummyValues:(NSDictionary *)dummyValues;
/**
 * Populate a dummy common schema app extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema app extension.
 */
+ (MSAppExtension *)appExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema protocol extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema protocol extension.
 */
+ (MSProtocolExtension *)protocolExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema network extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema network extension.
 */
+ (MSNetExtension *)netExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema sdk extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema sdk extension.
 */
+ (MSSDKExtension *)sdkExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema device extension.
 *
 * @param dummyValues Dummy values to create the extension.
 *
 * @return A dummy common schema device extension.
 */
+ (MSDeviceExtension *)deviceExtensionWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate a dummy common schema data.
 *
 * @param dummyValues Dummy values to create the data.
 *
 * @return A dummy common schema data.
 */
+ (MSCSData *)dataWithDummyValues:(NSDictionary *)dummyValues;

/**
 * Populate an abstract log with dummy values.
 *
 * @param log An abstract log to be filled with dummy values.
 */
+ (void)populateAbstractLogWithDummies:(MSAbstractLog *)log;

@end
