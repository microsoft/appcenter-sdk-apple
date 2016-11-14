#import <UIKit/UIAlertController.h>

@interface MSAlertAction : UIAlertAction

+ (instancetype)defaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;
+ (instancetype)cancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;
+ (instancetype)destructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

@end

@interface MSAlertController : UIAlertController

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message;

- (void)addDefaultActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;
- (void)addCancelActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;
- (void)addDestructiveActionWithTitle:(NSString *)title handler:(void (^)(UIAlertAction *action))handler;

- (void)show;

@end
