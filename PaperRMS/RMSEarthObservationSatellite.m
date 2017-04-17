//
//  RMSEarthObservationSatellite.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSEarthObservationSatellite.h"

#import "RMSImageDataUnit.h"
#import "RMSDataDownloadRequest.h"
#import "RMSSysthesisCalculateCenter.h"
#import "RMSDataDownloadJob.h"

@interface RMSEarthObservationSatellite ()

@property (nonatomic, strong, nonnull) NSMutableArray<RMSImageDataUnit *> *observationTaskQueue;
@property (nonatomic, strong, nullable) RMSImageDataUnit *currentTask;

@property (nonatomic, strong, nonnull) NSMutableArray<RMSImageDataUnit *> *iduBufferedQueue;

@property (nonatomic, strong, nonnull) NSMutableArray<RMSDataDownloadJob *> *schedualedDdjQueue;
@property (nonatomic, strong, nullable) RMSDataDownloadJob *currentDDJ;

@property (nonatomic, strong, nonnull) NSMutableArray<RMSDataDownloadJob *> *completedDDJs;

@end

#define DATA_DOWNLOAD_REQUEST_TIME_INTERVAL 60
@implementation RMSEarthObservationSatellite
{
    RMSSatelliteTime _ddrClock;
}

- (instancetype)initWithSatelliteID:(RMSSatelliteID)uniqueID
{
    self = [super init];
    
    if (self) {
        self.uniqueID = uniqueID;
        [self readInObservationTask];
        _ddrClock = DATA_DOWNLOAD_REQUEST_TIME_INTERVAL;
        _iduBufferedQueue = [[NSMutableArray alloc] init];
        _schedualedDdjQueue = [[NSMutableArray alloc] init];
        _completedDDJs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)readInObservationTask
{
    self.observationTaskQueue = [[NSMutableArray alloc] init];
    
    NSString *filePath = [NSString stringWithFormat:@"%@eos%02d_task.txt",FILE_INPUT_PATH_PREFIX_STRING, (self.uniqueID + 1)];
    NSLog(@"eos-%d task file path:%@",self.uniqueID, filePath);
    FILE *taskFile = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding], "r");
    assert(taskFile != NULL);
    
    RMSSatelliteTime producedTime;
    RMSDataSize size;
    while(fscanf(taskFile, "%lf %lf\n", &producedTime, &size) != EOF) {
        RMSImageDataUnit *unit = [[RMSImageDataUnit alloc] init];
        unit.producedTime = producedTime;
        unit.size = size;
        [self.observationTaskQueue addObject:unit];
    }
    
    fclose(taskFile);
    
    [self.observationTaskQueue sortUsingComparator:^NSComparisonResult(RMSImageDataUnit * _Nonnull obj1, RMSImageDataUnit * _Nonnull obj2) {
        if (obj1.producedTime < obj2.producedTime) {
            return NSOrderedAscending;
        }
        
        return NSOrderedDescending;
    }];
    
    NSLog(@"eos-%d read in %ld task", self.uniqueID, self.observationTaskQueue.count);
}

- (void)updateState
{
    [super updateState];
    
    // 是否有IDU产生
    if (self.currentTask == nil && self.observationTaskQueue.count > 0) {
        self.currentTask = [self.observationTaskQueue firstObject];
        [self.observationTaskQueue removeObjectAtIndex:0];
    }
    
    if (self.currentTask != nil) {
        if (self.systemTime >= self.currentTask.producedTime) {
            [self.iduBufferedQueue addObject:self.currentTask];
            self.currentTask = nil;
        }
    }
    
    // IDU传输
    if (self.currentDDJ == nil && self.schedualedDdjQueue.count > 0) {
        self.currentDDJ = [self.schedualedDdjQueue firstObject];
        [self.schedualedDdjQueue removeObjectAtIndex:0];
    }
    
    if (self.currentDDJ != nil) {
        if (self.systemTime >= self.currentDDJ.endTime) {
            [self.completedDDJs addObject:self.currentDDJ];
            self.currentDDJ = nil;
        }
    }
    
    
    // 每1min发送一次数据下传请求
    if (_ddrClock > 0) {
        _ddrClock -= STATE_UPDATE_TIME_STEP;
    }
    else {
        [self sendDataDownloadRequest];
        _ddrClock = DATA_DOWNLOAD_REQUEST_TIME_INTERVAL;
    }
    
}

- (void)sendDataDownloadRequest
{
    if (self.iduBufferedQueue.count <= 0) {
        return;
    }
    
    RMSDataDownloadRequest *request = [[RMSDataDownloadRequest alloc] init];
    request.eos = self;
    request.iduArray = self.iduBufferedQueue;
    
    RMSDataSize dataSize = 0;
    for (RMSImageDataUnit *idu in request.iduArray) {
        dataSize += idu.size;
    }
    request.dataSize = dataSize;
    
    [[RMSSysthesisCalculateCenter sharedSysthesisCalculateCenter] dataDownloadRequest:request];
}

- (void)schedualDDJ:(RMSDataDownloadJob *)ddj
{
    for (RMSImageDataUnit *idu in ddj.iduArray) {
        [self.iduBufferedQueue removeObject:idu];
    }
    
    [self.schedualedDdjQueue addObject:ddj];
}


- (void)stop
{
    // 统计各项指标
    
    // 数据下传量、数据产生总量、IDU下传量、IDU产生总量、IDU平均到地时长
    RMSDataSize downloadedData, producedData;
    RMSSatelliteTime iduDownloadedTimeCost;
    int downloadedIDU, producedIDU;
    
    downloadedData = producedData = 0;
    iduDownloadedTimeCost = 0;
    downloadedIDU = producedIDU = 0;
    
    for (RMSDataDownloadJob *ddj in self.completedDDJs) {
        downloadedData += ddj.dataSize;
        producedData += ddj.dataSize;
        
        for (RMSImageDataUnit *idu in ddj.iduArray) {
            ++downloadedIDU;
            ++producedIDU;
            iduDownloadedTimeCost += ddj.endTime - idu.producedTime;
        }
    }
    
    for (RMSDataDownloadJob *ddj in self.schedualedDdjQueue) {
        producedData += ddj.dataSize;
        producedIDU += ddj.iduArray.count;
    }
    
    for (RMSImageDataUnit *idu in self.iduBufferedQueue) {
        producedData += idu.size;
        ++producedIDU;
    }
    
    RMSSatelliteTime iduDownloadAverageTime = iduDownloadedTimeCost / downloadedIDU;
    
    // EOS两次connection之间的时间间隔
    RMSSatelliteTime connectionInterval, minConnectionInterval, maxConnectionInterval, aveConnectionInterval;
    RMSSatelliteTime lastConnectionTime, connectionIntervalAmount;
    long connectionBuilt, connectionSchedualed;
    
    connectionInterval = maxConnectionInterval = lastConnectionTime = connectionIntervalAmount = 0;
    minConnectionInterval = 100000000.0f;
    connectionBuilt = connectionSchedualed = 0;
    
    for (RMSDataDownloadJob *ddj in self.completedDDJs) {
        ++connectionBuilt;
        connectionInterval = ddj.startTime - lastConnectionTime;
        lastConnectionTime = ddj.startTime;
        connectionIntervalAmount += connectionInterval;
        
        if (connectionInterval < minConnectionInterval) {
            minConnectionInterval = connectionInterval;
        }
        
        if (connectionInterval > maxConnectionInterval) {
            maxConnectionInterval = connectionInterval;
        }
        
    }
    
    connectionSchedualed = connectionBuilt + self.schedualedDdjQueue.count;
    
    aveConnectionInterval = connectionIntervalAmount / connectionBuilt;
    
    // 写日志
    NSString *logFilePath = [NSString stringWithFormat:@"%@eos_log_%d.txt", FILE_OUTPUT_PATH_PREFIX_STRING, self.uniqueID];
    FILE *logFile = fopen([logFilePath cStringUsingEncoding:NSUTF8StringEncoding], "w");
    assert(logFile != NULL);
    
    fprintf(logFile, "%d idu produced and %d idu downloaded percentage %lf\n", producedIDU, downloadedIDU, (double)downloadedIDU / producedIDU);
    fprintf(logFile, "%lf data produced and %lf data downloaded percentage %lf\n", producedData, downloadedData, (double)downloadedData / producedData);
    fprintf(logFile, "idu average download time %lf\n", iduDownloadAverageTime);
    
    fprintf(logFile, "%ld connection built, %ld connection schedualed\n", connectionBuilt, connectionSchedualed);
    fprintf(logFile, "connection interval: min-%lf max-%lf ave-%lf\n", minConnectionInterval, maxConnectionInterval, aveConnectionInterval);
    
    fclose(logFile);
    
}

- (RMSSatelliteTime)nearestTransmissionEnableTime
{
    if (self.schedualedDdjQueue.count > 0) {
        RMSDataDownloadJob *ddj = [self.schedualedDdjQueue lastObject];
        return ddj.endTime + EOS_SWITCH_TIME;
    }
    
    if (self.currentDDJ != nil) {
        return self.currentDDJ.endTime + EOS_SWITCH_TIME;
    }
    
    return self.systemTime + EOS_SWITCH_TIME;
}

@end


