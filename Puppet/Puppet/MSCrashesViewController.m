/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AppDelegate.h"
#import "MSCrashes.h"
#import "MSCrashesViewController.h"

#import "CrashLib.h"
#import <Photos/Photos.h>
#import <objc/runtime.h>

@interface MSCrashesViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSDictionary *knownCrashes;

@end

@implementation MSCrashesViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self pokeAllCrashes];
  
  NSMutableArray *crashes = [NSMutableArray arrayWithArray:[MSCrash allCrashes]];
  [crashes sortUsingComparator:^NSComparisonResult(MSCrash *obj1, MSCrash *obj2) {
    if ([obj1.category isEqualToString:obj2.category]) {
      return [obj1.title compare:obj2.title];
    } else {
      return [obj1.category compare:obj2.category];
    }
  }];
  
  NSMutableDictionary *categories = @{}.mutableCopy;
  
  for (MSCrash *crash in crashes)
    categories[crash.category] = [(categories[crash.category] ?: @[]) arrayByAddingObject:crash];
  
  self.knownCrashes = categories.copy;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Private

- (void)pokeAllCrashes
{
  unsigned int nclasses = 0;
  Class *classes = objc_copyClassList(&nclasses);
  
  [MSCrash removeAllCrashes];
  for (unsigned int i = 0; i < nclasses; ++i) {
    if (classes[i] &&
        class_getSuperclass(classes[i]) == [MSCrash class] &&
        class_respondsToSelector(classes[i], @selector(methodSignatureForSelector:)) &&
        classes[i] != [MSCrash class])
    {
      [MSCrash registerCrash:[[classes[i] alloc] init]];
    }
  }
  free(classes);
}

- (NSArray *)sortedAllKeys {
  NSMutableArray *result = [NSMutableArray arrayWithArray:self.knownCrashes.allKeys];
  [result sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
    return [obj1 compare:obj2];
  }];
  return result;
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSCrashes setEnabled:sender.on];
  sender.on = [MSCrashes isEnabled];
}

- (MSCrash *)crashByIndexPath:(NSIndexPath *)indexPath {
  return (MSCrash *)(((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)indexPath.section - 1]])[(NSUInteger)indexPath.row]);
}

#pragma mark - Tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.knownCrashes.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  // Settings section.
  if (section == 0) {
    return 3;
  }
  return (NSInteger)((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)section - 1]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  // Settings section.
  if (section == 0) {
    return @"Crashes Settings";
  }
  return self.sortedAllKeys[(NSUInteger)section - 1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *CellIdentifier = nil;

  // Settings cell id.
  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      CellIdentifier = @"enable";
    } else {
      CellIdentifier = @"attachment";
    }
  }

  // Crash cell id.
  else {
    CellIdentifier = @"crash";
  }

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  // Settings cells.
  if (indexPath.section == 0) {
    
    // Enable.
    if (indexPath.row == 0) {
      
      // Find switch in subviews.
      for (id view in cell.contentView.subviews) {
        if ([view isKindOfClass:[UISwitch class]]) {
          ((UISwitch *)view).on = [MSCrashes isEnabled];
          break;
        }
      }
      
    // Text attachment.
    } else if (indexPath.row == 1) {
      cell.textLabel.text = @"Text Attachment";
      NSString *text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
      cell.detailTextLabel.text = text != nil && text.length > 0 ? text : @" ";
      
    // Binary attachment.
    } else if (indexPath.row == 2) {
      cell.textLabel.text = @"Binary Attachment";
      NSURL *referenceUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"fileAttachment"];
      cell.detailTextLabel.text = referenceUrl ? [referenceUrl absoluteString] : @" ";
      
      // Read async to display size instead of url.
      if (referenceUrl) {
        PHAsset *asset = [[PHAsset fetchAssetsWithALAssetURLs:@[referenceUrl] options:nil] lastObject];
        if (asset) {
          [[PHImageManager defaultManager]
              requestImageDataForAsset:asset
                               options:nil
                         resultHandler:^(NSData *_Nullable imageData,
                                         __unused NSString *_Nullable dataUTI,
                                         __unused UIImageOrientation orientation,
                                         __unused NSDictionary *_Nullable info) {
                           cell.detailTextLabel.text =
                               [NSByteCountFormatter stringFromByteCount:[imageData length]
                                                              countStyle:NSByteCountFormatterCountStyleBinary];
                         }];
        }
      }
    }
  }

  // Crash cell.
  else if (indexPath.section > 0) {
    MSCrash *crash = [self crashByIndexPath:indexPath];
    cell.textLabel.text = crash.title;
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  // Crash cell.
  if (indexPath.section > 0) {
    __block MSCrash *crash = [self crashByIndexPath:indexPath];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:crash.title
                                                                   message:crash.desc
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *crashAction = [UIAlertAction actionWithTitle:@"Crash"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction *action) {
                                                          [crash crash];
                                                        }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                           [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                                         }];
    [alert addAction:crashAction];
    [alert addAction:cancelAction];
    
    // Support display in iPad.
    alert.popoverPresentationController.sourceView = tableView;
    alert.popoverPresentationController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
    
    [self presentViewController:alert animated:YES completion:nil];
  }

  // Settings cells.
  else if (indexPath.section == 0) {
    
    // Text attachment.
    if (indexPath.row == 1) {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Text attachment"
                                                                     message:nil
                                                              preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction *crashAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                            NSString *result = alert.textFields[0].text;
                                                            if (result != nil && result.length > 0) {
                                                              [[NSUserDefaults standardUserDefaults] setObject:result forKey:@"textAttachment"];
                                                            } else {
                                                              [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"textAttachment"];
                                                            }
                                                            [tableView reloadData];
                                                          }];
      UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                             style:UIAlertActionStyleCancel
                                                           handler:nil];
      [alert addAction:crashAction];
      [alert addAction:cancelAction];
      [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
      }];
      
      [self presentViewController:alert animated:YES completion:nil];
      
    // Binary attachment.
    } else if (indexPath.row == 2) {
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
          UIImagePickerController *picker = [[UIImagePickerController alloc] init];
          picker.delegate = self;
          [self presentViewController:picker animated:YES completion:nil];
        }
      }];
    }
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
  if (referenceUrl) {
    [[NSUserDefaults standardUserDefaults] setURL:referenceUrl forKey:@"fileAttachment"];
    [self.tableView reloadData];
  }
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fileAttachment"];
  [self.tableView reloadData];
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
