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

@property (nonatomic, strong, nonnull) NSMutableArray<RMSDataDownloadJob *> *schedualedDownloadJob;
@property (nonatomic, strong, nullable) RMSDataDownloadJob *currentJob;
@property (nonatomic, strong, nonnull) NSMutableArray<RMSDataDownloadJob *> *completedDownloadJob;

@end



@implementation RMSDataRelaySatellite

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _schedualedDownloadJob = [[NSMutableArray alloc] init];
        _completedDownloadJob = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)updateState
{
    [super updateState];
    
    // 是否有任务要执行
    if (self.currentJob == nil && self.schedualedDownloadJob.count > 0) {
        self.currentJob = [self.schedualedDownloadJob firstObject];
        [self.schedualedDownloadJob removeObjectAtIndex:0];
    }
    
    if (self.currentJob != nil) {
        if (self.systemTime > self.currentJob.endTime) {
            // TODO 做记录
            [self.completedDownloadJob addObject:self.currentJob];
            self.currentJob = nil;
        }
    }
}

- (RMSSatelliteTime)nearestServiceEnableTime
{
    if (self.schedualedDownloadJob.count > 0) {
        RMSDataDownloadJob *job = [self.schedualedDownloadJob lastObject];
        return job.endTime + DRS_SWITCH_TIME;
    }
    
    if (self.currentJob != nil) {
        return self.currentJob.endTime + DRS_SWITCH_TIME;
    }

    return self.systemTime + DRS_SWITCH_TIME;
}

- (void)schedualDDJ:(RMSDataDownloadJob *)ddj
{
    [self.schedualedDownloadJob addObject:ddj];
}

- (void)stop
{
    NSString *logFilePath = [NSString stringWithFormat:@"%@drs_log_%d.txt", FILE_OUTPUT_PATH_PREFIX_STRING, self.uniqueID];
    FILE *logFile = fopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "w");
    assert(logFile != NULL);
    
    long completedConnection, schedualedConnection;
    completedConnection = schedualedConnection = 0;
    completedConnection = self.completedDownloadJob.count;
    schedualedConnection = completedConnection + self.schedualedDownloadJob.count;
    
    fprintf(logFile, "completedConnection %ld, schedualedConnection %ld, percentage %lf\n", completedConnection, schedualedConnection, (double)completedConnection / schedualedConnection);
    
    bool abConstrain = false;
    RMSSatelliteTime lastConnectionEndTime = 0.0f;
    for (RMSDataDownloadJob *ddj in self.completedDownloadJob) {
        if (ddj.startTime - lastConnectionEndTime < DRS_SWITCH_TIME - 1) {
            abConstrain = true;
            NSLog(@"lastConnection:%lf thisDDJ:%lf", lastConnectionEndTime, ddj.startTime);
            break;
        }
        
        lastConnectionEndTime = ddj.endTime;
    }
    
//    if (!abConstrain) {
//        for (RMSDataDownloadJob *ddj in self.schedualedDownloadJob) {
//            if (ddj.startTime - lastConnectionEndTime < DRS_SWITCH_TIME) {
//                abConstrain = true;
//                break;
//            }
//            
//            lastConnectionEndTime = ddj.endTime;
//        }
//    }
    
    if (abConstrain) {
        fprintf(logFile, "ab constrain\n");
    }
    else {
        fprintf(logFile, "non ab constrain\n");
    }
}

@end
