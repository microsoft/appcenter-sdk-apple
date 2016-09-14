//
//  MainViewController.m
//  Puppet
//
//  Created by Mehrdad Mozafari on 7/15/16.
//  Copyright © 2016 Mehrdad Mozafari. All rights reserved.
//

#import "SNMAnalyticsViewController.h"
#import "SonomaAnalytics.h"

@implementation SNMAnalyticsViewController


#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Analytics";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  }else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  switch (section) {
    // Actions
    case 0: {
      return 4;
    }
    // Settings
    case 1: {
      return 1;
    }
    default:
      return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case 0: {
      return @"Actions";
    }
    case 1: {
        return @"Settings";
    }
    default:
      return 0;
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  switch ([indexPath section]) {
    case 0: {
      
      // Configure action cell...
      switch (indexPath.row) {
        case 0: {
          cell.textLabel.text = NSLocalizedString(@"Track Event", @"");
          break;
        }
          
        case 1: {
          cell.textLabel.text = NSLocalizedString(@"Track Event with Properties", @"");
          break;
        }
          
        case 2: {
          cell.textLabel.text = NSLocalizedString(@"Track Page", @"");
          break;
        }
          
        case 3: {
          cell.textLabel.text = NSLocalizedString(@"Track Page with Properties", @"");
          break;
        }
          
        default:
          break;
      }
      
      break;
    }
    case 1: {
      // Configure setting cell...
      switch (indexPath.row) {
        case 0: {
          cell.textLabel.text = NSLocalizedString(@"Feature Enabled", @"");
          cell.userInteractionEnabled = NO;
          break;
        }
          
        default:
          break;
      }
      break;
    }
      
    default:
      break;
  }

  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  switch ([indexPath section]) {
    case 0: {
      
      // Actions
      switch (indexPath.row) {
        case 0: {
          [SNMAnalytics trackEvent:@"myEvent" withProperties:nil];
          break;
        }
        case 1: {
          NSDictionary *properties = @{@"gender" : @"male", @"age" : @(20), @"title" : @"SDE"};
          [SNMAnalytics trackEvent:@"myEvent" withProperties:properties];
          break;
        }
        case 2: {
          [SNMAnalytics trackPage:@"myPage" withProperties:nil];
          break;
        }
          
        case 3: {
          NSDictionary *properties = @{@"gender" : @"female", @"age" : @(28), @"title" : @"PM"};
          [SNMAnalytics trackPage:@"myPage" withProperties:properties];
          break;
        }
        default:
          break;
      }
      
      break;
    }
      // Settings
    case 1: {
    
      switch (indexPath.row) {
        case 0: {
          // TODO
          break;
        }
        default:
          break;
      }
      break;
    }
      
    default:
      break;
  }
}
@end
