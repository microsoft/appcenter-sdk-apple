#import "MSAlertController.h"

// NSAlertFirstButtonReturn	= 1000
static const int DEFAULT_SHIFT = 1000;

@interface MSAlertController ()

@property(nonatomic) NSMutableDictionary *handlers;

@end

@implementation MSAlertController

+ (MSAlertController *)alertControllerWithTitle:(NSString *)title
                                        message:(NSString *)message
                                          style:(NSAlertStyle)style {
  MSAlertController *alert = [MSAlertController new];
  alert.messageText = title;
  alert.informativeText = message;
  alert.alertStyle = style;
  alert.handlers = [NSMutableDictionary new];
  return alert;
}

- (void)addActionWithTitle:(NSString *)title handler:(actionCallback)handler {
  NSString *key = [NSString stringWithFormat:@"%lu", self.buttons.count + DEFAULT_SHIFT];
  [self.handlers setObject:handler forKey:key];
  [self addButtonWithTitle:title];
}

- (void)show {
  NSModalResponse response = [self runModal];
  actionCallback handler = [self.handlers objectForKey:[NSString stringWithFormat:@"%ld", (long)response]];
  if (handler) {
    handler();
  }
}

@end
