#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

@class MSAppExtension;
@class MSLocExtension;
@class MSNetExtension;
@class MSOSExtension;
@class MSProtocolExtension;
@class MSSDKExtension;
@class MSUserExtension;

/**
 * Part A extensions.
 */
@interface MSCSExtensions : NSObject <MSSerializableObject, MSModel>

/**
 * The Protocol extension.
 */
@property(nonatomic) MSProtocolExtension *protocolExt;

/**
 * The User extension.
 */
@property(nonatomic) MSUserExtension *userExt;

/**
 * The OS extension.
 */
@property(nonatomic) MSOSExtension *osExt;

/**
 * The App extension.
 */
@property(nonatomic) MSAppExtension *appExt;

/**
 * The network extension.
 */
@property(nonatomic) MSNetExtension *netExt;

/**
 * The SDK extension.
 */
@property(nonatomic) MSSDKExtension *sdkExt;

/**
 * The Loc extension.
 */
@property(nonatomic) MSLocExtension *locExt;

@end
