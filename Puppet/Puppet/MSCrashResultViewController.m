/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "Constants.h"
#import "MSCrashes.h"
#import "MSCrashResultViewController.h"

@interface MSCrashResultViewController ()

@property (weak, nonatomic) IBOutlet UILabel *hasCrashedInLastSessionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sendingErrorReportLabel;
@property (weak, nonatomic) IBOutlet UILabel *sentErrorReportLabel;
@property (weak, nonatomic) IBOutlet UILabel *failedToSendErrorReportLabel;
@property (weak, nonatomic) IBOutlet UILabel *shouldProcessErrorReportLabel;
@property (weak, nonatomic) IBOutlet UILabel *shouldAwaitUserConfirmationLabel;

@end

@implementation MSCrashResultViewController

#pragma mark - View controller

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldProcessErrorReportEvent:)
                                                 name:kShouldProcessErrorReportEvent
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willSendErrorReportEvent:)
                                                 name:kWillSendErrorReportEvent
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSucceedSendingErrorReportEvent:)
                                                 name:kDidSucceedSendingErrorReportEvent
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailSendingErrorReportEvent:)
                                                 name:kDidFailSendingErrorReportEvent
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didShouldAwaitUserConfirmationEvent:)
                                                 name:kDidShouldAwaitUserConfirmationEvent
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if ([MSCrashes hasCrashedInLastSession]) {
    self.hasCrashedInLastSessionLabel.text = kHasCrashedInLastSessionText;
  }
}

#pragma mark - Callbacks

-(void)shouldProcessErrorReportEvent:(NSNotification *) notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.shouldProcessErrorReportLabel.text = kDidShouldProcessErrorReportText;
    [self reloadCells];
  });
}

-(void)willSendErrorReportEvent:(NSNotification *) notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.sendingErrorReportLabel.text = kDidSendingErrorReportText;
    [self reloadCells];
  });
}

-(void)didSucceedSendingErrorReportEvent:(NSNotification *) notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.sentErrorReportLabel.text = kDidSentErrorReportText;
    [self reloadCells];
  });
}

-(void)didFailSendingErrorReportEvent:(NSNotification *) notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.failedToSendErrorReportLabel.text = kDidFailedToSendErrorReportText;
    [self reloadCells];
  });
}

-(void)didShouldAwaitUserConfirmationEvent:(NSNotification *) notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.shouldAwaitUserConfirmationLabel.text = kDidShouldAwaitUserConfirmationText;
    [self reloadCells];
  });
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch(indexPath.section) {
    case 1:
      switch (indexPath.row) {
        case 0:
          self.hasCrashedInLastSessionLabel.text = @"";
          self.sendingErrorReportLabel.text = @"";
          self.sentErrorReportLabel.text = @"";
          self.failedToSendErrorReportLabel.text = @"";
          self.shouldProcessErrorReportLabel.text = @"";
          self.shouldAwaitUserConfirmationLabel.text = @"";
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
  int rowsInSection = (int)[self.tableView numberOfRowsInSection:0];
  for(int row = 0; row < rowsInSection; ++row) {
    [rows addObject:[NSIndexPath indexPathForRow:row inSection:0]];
  }
  [self.tableView reloadRowsAtIndexPaths:rows
                        withRowAnimation:UITableViewRowAnimationNone];
}

@end
