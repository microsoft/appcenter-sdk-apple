#import <Foundation/Foundation.h>

#import "MSModel.h"
#import "MSSerializableObject.h"

/**
 * The Protocol extension contains device specific information.
 */
@interface MSProtocolExtension : NSObject <MSSerializableObject, MSModel>

/**
 * Ticket keys.
 */
@property(nonatomic) NSArray<NSString *> *ticketKeys;

/**
 * The device's manufacturer.
 */
@property(nonatomic, copy) NSString *devMake;

/**
 * The device's model.
 */
@property(nonatomic, copy) NSString *devModel;

@end
