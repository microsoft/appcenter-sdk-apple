#import <Foundation/Foundation.h>

#import "MSAnalyticsTransmissionTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSPropertyConfigurator ()

@property(nonatomic, copy) NSString *appName;

@property(nonatomic, copy) NSString *appVersion;

@property(nonatomic, copy) NSString *appLocale;

@property(nonatomic, weak) MSAnalyticsTransmissionTarget *transmissionTarget;

- (instancetype)initWithTransmissionTarget:(MSAnalyticsTransmissionTarget *)transmissionTarget;

@end

NS_ASSUME_NONNULL_END
