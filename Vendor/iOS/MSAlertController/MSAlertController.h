#import <UIKit/UIAlertController.h>

@interface MSAlertAction : UIAlertAction

+ (instancetype)defaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

+ (instancetype)cancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

+ (instancetype)destructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

@end

/**
 * A custom subclass of UIAlertcontroller that can be called from other classes than a UIViewController subclass, e.g. from an app's
 * appication delegate.
 */
@interface MSAlertController : UIAlertController

/**
 * Initializes a alert controller object.
 *
 * @param title The title label of the alert controller.
 * @param message  The message of the alert controller.
 * @return instance of MSAlertController.
 */
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message;

/**
 * Add a default action to the alert controller.
 *
 * @param title The action's title.
 * @param handler A block that will be executed if the user chooses the action.
 */
- (void)addDefaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

/**
 * Add a cancel action to the alert controller.
 *
 * @param title The action's title.
 * @param handler A block that will be executed if the user chooses the action.
 */
- (void)addCancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

/**
 * Add a desctructive action to the alert controller.
 *
 * @param title  The action's title.
 * @param handler A block that will be executed if the user chooses the action.
 */
- (void)addDestructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

/**
 * Add a preferred action to the alert controller.
 *
 * @param title  The action's title.
 * @param handler A block that will be executed if the user chooses the action.
 *
 */
- (void)addPreferredActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

/**
 * Show the alert controller to the user.
 */
- (void)show;

/**
 * Show the alert controller to the user.
 *
 * @param animated Whether this alert will be displayed animated or not.
 */
- (void)showAnimated:(BOOL)animated;

/**
 * Replace an existing alert controller submitted to this class.
 *
 * @param alert  Alert to replace.
 *
 * @discussion If the alert to replace is not found then this call is equivalent to @see show.
 */
- (void)replaceAlert:(MSAlertController *)alert;

/**
 * Replace an existing alert controller submitted to this class.
 *
 * @param alert  Alert to replace.
 * @param animated Whether this alert will be displayed animated or not.
 *
 * @discussion If the alert to replace is not found then this call is equivalent to @see showAnimated:.
 */
- (void)replaceAlert:(MSAlertController *)alert animated:(BOOL)animated;

@end
