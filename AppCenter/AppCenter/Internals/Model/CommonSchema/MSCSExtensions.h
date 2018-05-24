#import <Foundation/Foundation.h>
#import "MSProtocolExtension.h"
#import "MSUserExtension.h"
#import "MSOsExtension.h"
#import "MSAppExtension.h"
#import "MSNetExtension.h"
#import "MSSdkExtension.h"
#import "MSLocExtension.h"
#import "MSSerializableObject.h"
#import "MSModel.h"

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
@property(nonatomic) MSOsExtension *osExt;

/**
 * The App extension.
 */
@property(nonatomic) MSAppExtension *appExt;

/**
 * The Net extension.
 */
@property(nonatomic) MSNetExtension *netExt;

/**
 * The SDK extension.
 */
@property(nonatomic) MSSdkExtension *sdkExt;

/**
 * The Loc extension.
 */
@property(nonatomic) MSLocExtension *locExt;

@end
