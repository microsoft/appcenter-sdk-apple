#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

typedef void (^actionCallback)();

NS_ASSUME_NONNULL_BEGIN

@interface MSAlertController : NSAlert

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
