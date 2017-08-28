#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

typedef void (^actionCallback)();

NS_ASSUME_NONNULL_BEGIN

@interface MSAlertController : NSAlert

/**
 * Initializes a alert controller object.
 *
 * @param title The title label of the alert controller.
 * @param message The message of the alert controller.
 * @param style The style of alert controller.
 * @return instance of MSAlertController.
 */
+ (MSAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style;

/**
 * Add a action to the alert controller.
 *
 * @param title The action's title.
 * @param handler A block that will be executed if the user chooses the action.
 */
- (void)addActionWithTitle:(NSString *)title handler:(actionCallback)handler;

/**
 * Show the alert controller to the user.
 */
- (void)show;

@end

NS_ASSUME_NONNULL_END
