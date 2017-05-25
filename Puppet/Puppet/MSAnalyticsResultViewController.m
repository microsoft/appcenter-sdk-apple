/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Constants.h"
#import "EventLog.h"
#import "MSAnalyticsResultViewController.h"

@interface MSAnalyticsResultViewController ()

@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventPropsLabel;
@property (weak, nonatomic) IBOutlet UILabel *didSentEventLabel;
@property (weak, nonatomic) IBOutlet UILabel *didSendingEventLabel;
@property (weak, nonatomic) IBOutlet UILabel *didFailedToSendEventLabel;

@end

@implementation MSAnalyticsResultViewController

#pragma mark - view controller

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willSendEventLog:)
                                                 name:kWillSendEventLog
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSucceedSendingEventLog:)
                                                 name:kDidSucceedSendingEventLog
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailSendingEventLog:)
                                                 name:kDidFailSendingEventLog
                                               object:nil];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Callbacks

-(void)willSendEventLog:(NSNotification *) notification {
  id log = notification.object;
  self.eventNameLabel.text = [log eventName];
  self.eventPropsLabel.text = [NSString stringWithFormat:@"%d", [log properties].count];
  self.didSendingEventLabel.text = kDidSendingEventText;
  [self reloadCells];
}

-(void)didSucceedSendingEventLog:(NSNotification *) notification {
  id log = notification.object;
  self.eventNameLabel.text = [log eventName];
  self.eventPropsLabel.text = [NSString stringWithFormat:@"%d", [log properties].count];
  self.didSentEventLabel.text = kDidSentEventText;
  [self reloadCells];
}

-(void)didFailSendingEventLog:(NSNotification *) notification {
  id log = notification.object;
  self.eventNameLabel.text = [log eventName];
  self.eventPropsLabel.text = [NSString stringWithFormat:@"%d", [log properties].count];
  self.didFailedToSendEventLabel.text = kDidFailedToSendEventText;
  [self reloadCells];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch(indexPath.section) {
    case 1:
      switch (indexPath.row) {
        case 0:
          self.eventNameLabel.text = @"";
          self.eventPropsLabel.text = @"";
          self.didSentEventLabel.text = @"";
          self.didSendingEventLabel.text = @"";
          self.didFailedToSendEventLabel.text = @"";
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}

- (void)reloadCells {
  NSMutableArray<NSIndexPath*> *rows = [NSMutableArray new];
  [rows addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
  [rows addObject:[NSIndexPath indexPathForRow:1 inSection:0]];
  [rows addObject:[NSIndexPath indexPathForRow:2 inSection:0]];
  [rows addObject:[NSIndexPath indexPathForRow:3 inSection:0]];
  [rows addObject:[NSIndexPath indexPathForRow:4 inSection:0]];
  [self.refreshControl beginRefreshing];
  [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationNone];
  [self.refreshControl beginRefreshing];
}

@end
