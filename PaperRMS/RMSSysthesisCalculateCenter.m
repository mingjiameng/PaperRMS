//
//  RMSSysthesisCalculateCenter.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSSysthesisCalculateCenter.h"
#import "RMSDataDownloadJob.h"
#import "RMSCoreCenter.h"
#import "RMSMath.h"

@interface RMSSysthesisCalculateCenter ()

// download access request pool
@property (nonatomic, strong, nonnull) NSMutableDictionary *ddrPool;
@property (nonatomic) RMSSatelliteTime systemTime;

@end


#define FIRE_CLOCK_INTERVAL 300
@implementation RMSSysthesisCalculateCenter
{
    double calcuFireClock;
}

+ (instancetype)sharedSysthesisCalculateCenter
{
    static dispatch_once_t onceToken;
    static RMSSysthesisCalculateCenter *center = nil;
    
    dispatch_once(&onceToken, ^{
        center = [[RMSSysthesisCalculateCenter alloc] init];
    });
    
    return center;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _ddrPool = [[NSMutableDictionary alloc] init];
        calcuFireClock = FIRE_CLOCK_INTERVAL;
        _systemTime = 0;
        
    }
    
    return self;
}

- (void)updateState
{
    _systemTime += STATE_UPDATE_TIME_STEP;
    
    if (calcuFireClock > 0) {
        calcuFireClock -= STATE_UPDATE_TIME_STEP;
    }
    else {
        [self schedualDDJ];
        
        calcuFireClock = FIRE_CLOCK_INTERVAL;
    }
}

- (void)dataDownloadRequest:(RMSDataDownloadRequest *)request
{
    [self.ddrPool setObject:request forKey:[NSNumber numberWithInteger:request.eos.uniqueID]];
}

// schedual
- (void)schedualDDJ
{
    NSArray *DDJArr = [self produceDDJ];
    [self calcuPI:DDJArr];
    NSArray *validDDJArr = [self selectDDJ:DDJArr];
    [[RMSCoreCenter sharedCoreCenter] assignDDJ:validDDJArr];
}

- (NSArray<RMSDataDownloadJob *> *)produceDDJ
{
    RMSSatelliteTime w_k_i_s, w_k_i_e;
    RMSSatelliteTime t_i_s, t_k_s, t_k_i_s, t_k_i_e;
    RMSDataSize B_k, C_u_x, C_k_i_x;
    RMSSatelliteTime T_k_i_x, t_k_i_x_s, t_k_i_x_e;
    NSMutableArray<RMSDataDownloadJob *> *ddjArr = [NSMutableArray arrayWithCapacity:self.drsArray.count * self.ddrPool.allKeys.count];
    for (RMSDataRelaySatellite *drs in self.drsArray) {
        for (NSNumber *eosID in self.ddrPool.allKeys) {
            RMSDataDownloadRequest *ddr = [self.ddrPool objectForKey:eosID];
            RMSTimeRange nextOrbitPeriod = {_systemTime, _systemTime + ddr.eos.orbitPeriod};
            RMSTimeRange nextVisibleTimeWindow = [RMSMath nextVisibleTimeRangeBetweenEOS:ddr.eos andDRS:drs inTimeRange:nextOrbitPeriod];
            w_k_i_s = nextVisibleTimeWindow.beginAt;
            w_k_i_e = nextVisibleTimeWindow.beginAt + nextVisibleTimeWindow.length;
            t_i_s = drs.nearestServiceEnableTime;
            t_k_s = ddr.eos.nearestTransmissionEnableTime;
            t_k_i_s = MAX(t_i_s, w_k_i_s);
            t_k_i_s = MAX(t_k_i_s, t_k_s);
            t_k_i_e = MIN(t_k_i_s + LONGEST_SWITCH_ON_TIME, w_k_i_e);
            
            if (t_k_i_e <= t_k_i_s) {
                continue;
            }
            
            B_k = ddr.eos.bandwidth;
            C_u_x = B_k * (t_k_i_e - t_k_i_s);
            C_k_i_x = 0.0f;
            NSMutableArray<RMSImageDataUnit *> *permittedIDUArr = [[NSMutableArray alloc] init];
            for (RMSImageDataUnit *idu in ddr.iduArray) {
                if (C_k_i_x + idu.size < C_u_x) {
                    [permittedIDUArr addObject:idu];
                    C_k_i_x += idu.size;
                }
                else {
                    break;
                }
            }
            
            T_k_i_x = C_k_i_x / B_k;
            t_k_i_x_s = t_k_i_s;
            t_k_i_x_e = MIN(t_k_i_e, t_k_i_s + T_k_i_x);
            
            RMSDataDownloadJob *job = [[RMSDataDownloadJob alloc] init];
            job.eos = ddr.eos;
            job.drs = drs;
            job.startTime = t_k_i_x_s;
            job.endTime = t_k_i_x_e;
            job.waitingTime = t_k_i_x_s - t_i_s;
            job.iduArray = permittedIDUArr;
            job.dataSize = C_k_i_x;
            
            [ddjArr addObject:job];
        }
    }
    
    [self.ddrPool removeAllObjects];
}

- (void)calcuPI:(NSArray<RMSDataDownloadJob *> *)DDJArr
{
    RMSDataSize SUM_C_k_i_x = 0;
    for (RMSDataDownloadJob *job in DDJArr) {
        SUM_C_k_i_x += job.dataSize;
    }
    
    double TF_k_i_x, QOS_k_i_x, E_k_i_x, BU_k_i_x;
    RMSSatelliteTime t = _systemTime;
    RMSSatelliteTime duration;
    for (RMSDataDownloadJob *job in DDJArr) {
        TF_k_i_x = job.dataSize / SUM_C_k_i_x;
        
        E_k_i_x = 0;
        for (RMSImageDataUnit *idu in job.iduArray) {
            E_k_i_x += idu.size / job.dataSize * (t - idu.producedTime);
        }
        
        QOS_k_i_x = log(E_k_i_x / job.eos.orbitPeriod - 1);
        
        duration = job.endTime - job.startTime;
        BU_k_i_x = duration / (duration + job.waitingTime);
        
        job.PI = TF_k_i_x * QOS_k_i_x * BU_k_i_x;
    }
}

- (NSArray<RMSDataDownloadJob *> *)selectDDJ:(NSArray<RMSDataDownloadJob *> *)DDJArr
{
    NSMutableArray<NSMutableArray *> *DDJGroups = [[NSMutableArray alloc] initWithCapacity:self.drsArray.count];
    for (int i = 0; i < self.drsArray.count; ++i) {
        [DDJGroups addObject:[NSMutableArray arrayWithCapacity:self.ddrPool.count]];
    }
    
    for (RMSDataDownloadJob *job in DDJArr) {
        NSMutableArray *group = [DDJGroups objectAtIndex:job.drs.uniqueID];
        [group addObject:job];
    }
    
    NSMutableArray<RMSDataDownloadJob *> *validJobs = [[NSMutableArray alloc] init];
    for (NSMutableArray *group in DDJGroups) {
        [validJobs addObject:[group firstObject]];
        [group removeObjectAtIndex:0];
    }
    
    bool duplicated = true;
    NSUInteger duplicatedIndex;
    RMSDataDownloadJob *duplicatedJob01, *duplicatedJob02;
    NSMutableArray<RMSDataDownloadJob *> *jobGroup01, *jobGroup02;
    while (duplicated) {
        duplicated = false;
        
        [validJobs sortUsingComparator:^NSComparisonResult(RMSDataDownloadJob * _Nonnull obj1, RMSDataDownloadJob * _Nonnull obj2) {
            if (obj1.eos.uniqueID < obj2.eos.uniqueID) {
                return NSOrderedAscending;
            }
            else if (obj1.eos.uniqueID == obj2.eos.uniqueID) {
                return NSOrderedSame;
            }
            
            return NSOrderedDescending;
        }];
        
        for (duplicatedIndex = 1; duplicatedIndex < validJobs.count; ++duplicatedIndex) {
            duplicatedJob01 = [validJobs objectAtIndex:duplicatedIndex - 1];
            duplicatedJob02 = [validJobs objectAtIndex:duplicatedIndex];
            if (duplicatedJob01.eos.uniqueID == duplicatedJob02.eos.uniqueID) {
                duplicated = true;
                break;
            }
        }
        
        
        if (duplicated) {
            if (duplicatedJob02.PI > duplicatedJob01.PI) {
                RMSDataDownloadJob *tmpJob = duplicatedJob01;
                duplicatedJob01 = duplicatedJob02;
                duplicatedJob02 = tmpJob;
            }
            
            jobGroup01 = [DDJGroups objectAtIndex:duplicatedJob01.drs.uniqueID];
            jobGroup02 = [DDJGroups objectAtIndex:duplicatedJob02.drs.uniqueID];
            
            if (jobGroup02.count > 0 || jobGroup01.count <= 0) {
                [validJobs removeObject:duplicatedJob02];
                if (jobGroup02.count > 0) {
                    [validJobs addObject:[jobGroup02 firstObject]];
                    [jobGroup02 removeObjectAtIndex:0];
                }
            }
            else {
                [validJobs removeObject:duplicatedJob01];
                if (jobGroup01.count > 0) {
                    [validJobs addObject:[jobGroup01 firstObject]];
                    [jobGroup01 removeObjectAtIndex:0];
                }
            }
        }
    }
    
    return validJobs;
}

@end
