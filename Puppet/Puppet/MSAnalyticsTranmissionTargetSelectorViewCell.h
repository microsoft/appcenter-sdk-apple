#import <UIKit/UIKit.h>

static const NSString *kMSEventPropertiesIdentifier = @"Event Arguments";

@interface MSAnalyticsTranmissionTargetSelectorViewCell : UITableViewCell

@property (nonatomic) void (^didSelectTransmissionTarget)(void);
@property (nonatomic) NSArray <NSString*> *transmissionTargetMapping;

- (NSString *)selectedTransmissionTarget;

@end
