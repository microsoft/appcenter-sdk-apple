#import "AppCenterDelegateObjC.h"
#import "AppDelegate.h"
#import "Constants.h"

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterPush;

@interface AppDelegate ()

@property NSWindowController *rootController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [MSAppCenter setLogLevel:MSLogLevelVerbose];

  // Set user id.
  NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
  if (userId) {
    [MSAppCenter setUserId:userId];
  }

  // Customize services.
  [self setupCrashes];
  [self setupPush];

  // Start AppCenter.
  [MSAppCenter start:@"d80aae71-af34-4e0c-af61-2381391c4a7a" withServices:@[ [MSAnalytics class], [MSCrashes class], [MSPush class] ]];
  [AppCenterProvider shared].appCenter = [[AppCenterDelegateObjC alloc] init];

  [self initUI];
}

#pragma mark - Private

- (void)initUI {
  NSStoryboard *mainStoryboard = [NSStoryboard storyboardWithName:kMSMainStoryboardName bundle:nil];
  self.rootController = (NSWindowController *)[mainStoryboard instantiateControllerWithIdentifier:@"rootController"];
  [self.rootController showWindow:self];
  [self.rootController.window makeKeyAndOrderFront:self];
}

- (void)setupCrashes {
  if ([MSCrashes hasCrashedInLastSession]) {
    MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
    NSLog(@"%@ We crashed with Signal: %@", kMSLogTag, errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"%@ OS Version is: %@", kMSLogTag, osVersion);
    NSLog(@"%@ App Version is: %@", kMSLogTag, appVersion);
    NSLog(@"%@ App Build is: %@", kMSLogTag, appBuild);
  }

  [MSCrashes setDelegate:self];
  [MSCrashes setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {

               // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
               NSAlert *alert = [[NSAlert alloc] init];
               [alert setMessageText:@"Sorry about that!"];
               [alert setInformativeText:@"Do you want to send an anonymous crash "
                                         @"report so we can fix the issue?"];
               [alert addButtonWithTitle:@"Always send"];
               [alert addButtonWithTitle:@"Send"];
               [alert addButtonWithTitle:@"Don't send"];
               [alert setAlertStyle:NSWarningAlertStyle];

               switch ([alert runModal]) {
               case NSAlertFirstButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                 break;
               case NSAlertSecondButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
                 break;
               case NSAlertThirdButtonReturn:
                 [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
                 break;
               default:
                 break;
               }

               return YES;
             })];
}

- (void)setupPush {
  [MSPush setDelegate:self];
  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Should process error report with: %@", kMSLogTag, errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Will send error report with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"%@ Did succeed error report sending with: %@", kMSLogTag, errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  NSLog(@"%@ Did fail sending report with: %@, and error: %@", kMSLogTag, errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes forErrorReport:(MSErrorReport *)errorReport {
  NSMutableArray *attachments = [[NSMutableArray alloc] init];

  // Text attachment.
  NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
  if (text != nil && text.length > 0) {
    MSErrorAttachmentLog *textAttachment = [MSErrorAttachmentLog attachmentWithText:text filename:@"user.log"];
    [attachments addObject:textAttachment];
  }

  // Binary attachment.
  NSURL *referenceUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"fileAttachment"];
  if (referenceUrl) {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:referenceUrl options:0 error:&error];
    if (data && !error) {
      CFStringRef UTI =
          UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[referenceUrl pathExtension], nil);
      NSString *MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
      CFRelease(UTI);
      MSErrorAttachmentLog *binaryAttachment =
          [MSErrorAttachmentLog attachmentWithBinary:data filename:referenceUrl.lastPathComponent contentType:MIMEType];
      [attachments addObject:binaryAttachment];
      NSLog(@"Add binary attachment with %tu bytes", [data length]);
    } else {
      NSLog(@"Couldn't read attachment file with error: %@", error.localizedDescription);
    }
  }
  return attachments;
}

#pragma mark - MSPushDelegate

- (void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"%@ Did register for remote notifications with device token.", kMSLogTag);
}

- (void)application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
  NSLog(@"%@ Did fail to register for remote notifications with error %@.", kMSLogTag, [error localizedDescription]);
}

- (void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *, id> *)userInfo {
  NSLog(@"%@ Did receive remote notification", kMSLogTag);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  NSLog(@"%@ Did receive user notification", kMSLogTag);
}

- (void)push:(MSPush *)push didReceivePushNotification:(MSPushNotification *)pushNotification {

  // Bring any window to foreground if it was miniaturized.
  for (NSWindow *window in [NSApp windows]) {
    if ([window isMiniaturized]) {
      [window deminiaturize:self];
      break;
    }
  }

  // Show alert for the notification.
  NSString *title = pushNotification.title ?: @"";
  NSString *message = pushNotification.message;
  NSMutableString *customData = nil;
  for (NSString *key in pushNotification.customData) {
    ([customData length] == 0) ? customData = [NSMutableString new] : [customData appendString:@", "];
    [customData appendFormat:@"%@: %@", key, [pushNotification.customData objectForKey:key]];
  }
  message = [NSString
      stringWithFormat:@"%@%@%@", (message ? message : @""), (message && customData ? @"\n" : @""), (customData ? customData : @"")];
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:title];
  [alert setInformativeText:message];
  [alert addButtonWithTitle:@"OK"];
  [alert runModal];
}

@end
