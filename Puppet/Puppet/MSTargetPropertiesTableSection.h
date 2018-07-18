#import "MSPropertiesTableSection.h"

@interface MSTargetPropertiesTableSection : MSPropertiesTableSection

@property(nonatomic)
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *propertiesPerTransmissionTargets;
@property(nonatomic) NSMutableDictionary<NSString *, MSAnalyticsTransmissionTarget *> *transmissionTargets;
@end
