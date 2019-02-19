//
//  MSConflictResolutionDelegate.h
//  AppCenterDataStorageIOS
//
//  Created by Mehrdad Mozafari on 2/15/19.
//  Copyright © 2019 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSConflictResolutionDelegate <NSObject>

- (id<NSObject>)resolveWithDocument:(id<NSObject>)localDocument remoteDocument:(id<NSObject>)remoteDocument;

@end

NS_ASSUME_NONNULL_END
