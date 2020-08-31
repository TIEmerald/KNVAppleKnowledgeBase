//
//  KNVRunLoopPlayGroundModel.h
//  Temp Objective C Playground Project
//
//  Created by UNDaniel on 27/8/20.
//  Copyright © 2020 UNDaniel. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNDRunLoopPlayGroundModel : NSObject

#pragma mark - General Methods
- (void)playWithRunLoop;
- (void)addAndScheduleATimer;
- (void)addAnObserver;

@end

@interface UNDRunLoopWorkerModel : NSObject

@end

NS_ASSUME_NONNULL_END
