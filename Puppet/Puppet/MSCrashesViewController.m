/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AppDelegate.h"
#import "MSCrashes.h"
#import "MSCrashesViewController.h"
#import "MSCrashesDetailViewController.h"

#import "CrashLib.h"
#import <objc/runtime.h>

@interface MSCrashesViewController ()

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
  
  return [result copy];
}

- (IBAction)enabledSwitchUpdated:(UISwitch *)sender {
  [MSCrashes setEnabled:sender.on];
  sender.on = [MSCrashes isEnabled];
}

#pragma mark - Tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.knownCrashes.count + 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  // Settings section.
  if (section == [tableView numberOfSections] - 1) {
    return 1;
  }

  // Crash result section.
  if (section == [tableView numberOfSections] - 2) {
    return 1;
  }
  return (NSInteger)((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)section]]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  // Settings section.
  if (section == [tableView numberOfSections] - 1) {
    return @"Settings";
  }

  // Crash result section.
  if (section == [tableView numberOfSections] - 2) {
    return @"Crash result";
  }
  return self.sortedAllKeys[(NSUInteger)section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *CellIdentifier = nil;

  // Settings cell id.
  if (indexPath.section == [tableView numberOfSections] - 1) {
    CellIdentifier = @"enable";
  }

  // Crash result cell id.
  else if (indexPath.section == [tableView numberOfSections] - 2) {
    CellIdentifier = @"crashResult";
  }

  // Crash cell id.
  else {
    CellIdentifier = @"crash";
  }

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

  // Settings cell.
  if (indexPath.section == [tableView numberOfSections] - 1) {

    // Find switch in subviews.
    for(id view in cell.contentView.subviews) {
      if([view isKindOfClass:[UISwitch class]]){
        ((UISwitch *)view).on = [MSCrashes isEnabled];
        break;
      }
    }
  }

  // Crash cell.
  else if (indexPath.section < [tableView numberOfSections] - 2) {
    MSCrash *crash = (MSCrash *)(((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)indexPath.section]])[(NSUInteger)indexPath.row]);
    cell.textLabel.text = crash.title;
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  if (![cell.reuseIdentifier isEqualToString:@"crashResult"]) {
    return;
  }
  [self.navigationController pushViewController:[AppDelegate crashResultViewController] animated:true];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"crash-detail"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    MSCrash *crash = (MSCrash *)(((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)indexPath.section]])[(NSUInteger)indexPath.row]);
    ((MSCrashesDetailViewController *)segue.destinationViewController).detailItem = crash;
  }
}

@end
