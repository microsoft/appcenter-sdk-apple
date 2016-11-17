/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSCrashes.h"
#import "MSCrashesReportsViewController.h"
#import "MSCrashesDetailViewController.h"

#import "CrashLib.h"
#import <objc/runtime.h>


@interface MSCrashesReportsViewController ()

@property(nonatomic,strong) NSDictionary *knownCrashes;

@end

@implementation MSCrashesReportsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Crashes";
  
  [self pokeAllCrashes];
  
  NSMutableArray *crashes = [NSMutableArray arrayWithArray:[CRLCrash allCrashes]];
  [crashes sortUsingComparator:^NSComparisonResult(CRLCrash *obj1, CRLCrash *obj2) {
    if ([obj1.category isEqualToString:obj2.category]) {
      return [obj1.title compare:obj2.title];
    } else {
      return [obj1.category compare:obj2.category];
    }
  }];
  
  NSMutableDictionary *categories = @{}.mutableCopy;
  
  for (CRLCrash *crash in crashes)
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
  
  for (unsigned int i = 0; i < nclasses; ++i) {
    if (classes[i] &&
        class_getSuperclass(classes[i]) == [CRLCrash class] &&
        class_respondsToSelector(classes[i], @selector(methodSignatureForSelector:)) &&
        classes[i] != [CRLCrash class])
    {
      [CRLCrash registerCrash:[[classes[i] alloc] init]];
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


- (void)enabledSwitchUpdated:(id)sender {
  UISwitch *enabledSwitch = (UISwitch *)sender;
  [MSCrashes setEnabled:enabledSwitch.on];
  enabledSwitch.on = [MSCrashes isEnabled];
}


#pragma mark - Tableview datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.knownCrashes.count + 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  BOOL isLast = (section == ([tableView numberOfSections] -1));

  if(isLast) {
    return 1;
  }
  else {
    return (NSInteger)((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)section]]).count;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  
  BOOL isLast = (section == ([tableView numberOfSections] -1));
  
  if(isLast) {
    return @"Settings";
  }
  else {
    return self.sortedAllKeys[(NSUInteger)section];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = nil;
  
  BOOL isLast = (indexPath.section == ([tableView numberOfSections] -1));
  
  CellIdentifier = isLast ? @"settings" : @"crash";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
      if(isLast) {
        // Settings
        switch (indexPath.row) {
          case 0: {
            // Define the cell title.
            NSString *title = NSLocalizedString(@"Set Enabled", nil);
            cell.textLabel.text = title;
            cell.accessibilityLabel = title;
            
            // Define the switch control and add it to the cell.
            UISwitch *enabledSwitch = [[UISwitch alloc] init];
            enabledSwitch.on = [MSCrashes isEnabled];
            CGSize switchSize = [enabledSwitch sizeThatFits:CGSizeZero];
            enabledSwitch.frame = CGRectMake(cell.contentView.bounds.size.width - switchSize.width - 10.0f,
                                             (cell.contentView.bounds.size.height - switchSize.height) / 2.0f,
                                             switchSize.width, switchSize.height);
            enabledSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            [enabledSwitch addTarget:self
                              action:@selector(enabledSwitchUpdated:)
                    forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:enabledSwitch];
            break;
          }
          default:
            break;
        }
      }
      else {
        //Crashes
        CRLCrash *crash = (CRLCrash *)(((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)indexPath.section]])[(NSUInteger)indexPath.row]);
        
        cell.textLabel.text = crash.title;
        
      }
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"showCrashDetail"]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    CRLCrash *crash = (CRLCrash *)(((NSArray *)self.knownCrashes[self.sortedAllKeys[(NSUInteger)indexPath.section]])[(NSUInteger)indexPath.row]);
    
    ((MSCrashesDetailViewController *)segue.destinationViewController).detailItem = crash;
  }
}


@end
