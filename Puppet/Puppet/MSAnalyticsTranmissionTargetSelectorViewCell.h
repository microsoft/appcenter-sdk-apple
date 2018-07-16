#import <UIKit/UIKit.h>

@interface MSAnalyticsTranmissionTargetSelectorViewCell : UITableViewCell

@property (nonatomic) void (^didSelectTransmissionTarget)(void);
@property (nonatomic) NSArray <NSString*> *transmissionTargetMapping;

- (NSString *)selectedTransmissionTarget;

@end
