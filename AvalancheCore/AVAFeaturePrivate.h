//
//  AVAFeaturePrivate.h
//  AvalancheSDK-iOS
//
//  Created by Christoph Wendt on 6/15/16.
//
//

#import "AVAFeature.h"

@interface AVAFeature ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *serverURL;

+ (id)sharedInstance;
- (void)startFeature;

@end
