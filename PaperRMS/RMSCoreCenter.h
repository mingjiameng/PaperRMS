//
//  RMSCoreCenter.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RMSDataDownloadJob;

@interface RMSCoreCenter : NSObject

@property (nonatomic) RMSSatelliteTime systemTime;

+ (instancetype)sharedCoreCenter;

- (void)fire;
- (void)assignDDJ:(NSArray<RMSDataDownloadJob *> *)DDJArr;

@end
