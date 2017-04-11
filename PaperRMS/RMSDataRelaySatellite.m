//
//  RMSDataRelaySatellite.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSDataRelaySatellite.h"
#import "RMSDataDownloadJob.h"

@interface RMSDataRelaySatellite ()

@property (nonatomic, strong, nonnull) NSMutableArray<RMSDataDownloadJob *> *downloadJobQueue;
@property (nonatomic, strong, nullable) RMSDataDownloadJob *currentJob;

@end



@implementation RMSDataRelaySatellite

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _downloadJobQueue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)updateState
{
    [super updateState];
    
    // 是否有任务要执行
    if (self.currentJob == nil && self.downloadJobQueue.count > 0) {
        self.currentJob = [self.downloadJobQueue objectAtIndex:0];
        [self.downloadJobQueue removeObjectAtIndex:0];
    }
    
    if (self.currentJob != nil) {
        if (self.systemTime > self.currentJob.endTime) {
            // TODO 做记录
            
            
            self.currentJob = nil;
        }
    }
}

- (RMSSatelliteTime)nearestServiceEnableTime
{
    if (self.downloadJobQueue.count > 0) {
        RMSDataDownloadJob *job = [self.downloadJobQueue lastObject];
        return job.endTime + DRS_SWITCH_TIME;
    }
    
    if (self.currentJob != nil) {
        return self.currentJob.endTime + DRS_SWITCH_TIME;
    }

    return self.systemTime + DRS_SWITCH_TIME;
}

- (void)schedualDDJ:(RMSDataDownloadJob *)ddj
{
    [self.downloadJobQueue addObject:ddj];
}

@end
