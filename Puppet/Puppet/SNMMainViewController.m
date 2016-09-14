//
//  MainViewController.m
//  Puppet
//
//  Created by Mehrdad Mozafari on 7/15/16.
//  Copyright © 2016 Mehrdad Mozafari. All rights reserved.
//

#import "SNMMainViewController.h"

@implementation SNMMainViewController


#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Puppet App";
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
  // Return the number of sections.
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  // Return the number of rows in the section.
  return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  // Configure the cell...
  switch (indexPath.row) {
    case 0: {
      cell.textLabel.text = NSLocalizedString(@"Send Log", @"");
      break;
    }
      
    case 1: {
      cell.textLabel.text = NSLocalizedString(@"Crash Reports", @"");
      break;
    }
      
    default:
      break;
  }
  
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  switch (indexPath.row) {
    case 0: {
      UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
      UIViewController* vc = [sb instantiateViewControllerWithIdentifier:@"analytics"];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }

    case 1: {
      UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
      UIViewController* vc = [sb instantiateViewControllerWithIdentifier:@"crashes"];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
      
    default:
      break;
  }
}
@end
