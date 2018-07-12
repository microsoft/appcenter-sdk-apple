#import "Constants.h"
#import "MSAnalyticsTranmissionTargetSelectorViewCell.h"

@interface MSAnalyticsTranmissionTargetSelectorViewCell ()

@property(weak, nonatomic) IBOutlet UISegmentedControl *transmissionTargetSelector;

@end

@implementation MSAnalyticsTranmissionTargetSelectorViewCell

- (void)awakeFromNib {
  [super awakeFromNib];
  _transmissionTargetMapping =
      @[ kMSEventPropertiesIdentifier, kMSTargetToken1, kMSTargetToken2, kMSRuntimeTargetToken ];
  _didSelectTransmissionTarget = ^() {
  };
  [_transmissionTargetSelector addTarget:self
                                  action:@selector(didSelectSegment)
                        forControlEvents:UIControlEventValueChanged];
}

- (NSString *)selectedTransmissionTarget {
  return self.transmissionTargetMapping[self.transmissionTargetSelector.selectedSegmentIndex];
}

- (void)didSelectSegment {
  self.didSelectTransmissionTarget();
}

@end
