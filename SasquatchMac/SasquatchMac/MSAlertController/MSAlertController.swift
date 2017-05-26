import Cocoa
import Foundation

class MSAlertController : NSAlert {

  // NSAlertFirstButtonReturn	= 1000
  private static let DEFAULT_SHIFT : Int = 1000;
  private let handlers : NSMutableDictionary = NSMutableDictionary();

  class func alertController(title : String, message : String, style : NSAlertStyle) -> MSAlertController {
    let alert : MSAlertController = MSAlertController();
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = style;
    return alert;
  }

  /**
   * Add a action to the alert controller.
   *
   * @param title The action's title.
   * @param handler A block that will be executed if the user chooses the action.
   */
  func addAction(title : String, handler : () -> Void) {
    let handlerKey : String = String(buttons.count + MSAlertController.DEFAULT_SHIFT);
    handlers.setValue(handler, forKey: handlerKey);
    addButton(withTitle: title);
  }

  /**
   * Show the alert controller to the user.
   */
  func show() {
    let handlerKey : Int = self.runModal();
    guard let handler : () -> Void = handlers.object(forKey: String(handlerKey)) as? () -> Void else {
      return;
    }
    handler();
  }
}
