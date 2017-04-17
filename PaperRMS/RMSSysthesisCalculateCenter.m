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
    double _calcuFireClock;
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
        _calcuFireClock = FIRE_CLOCK_INTERVAL;
        _systemTime = 0;
        
    }
    
    return self;
}

- (void)updateState
{
    _systemTime += STATE_UPDATE_TIME_STEP;
    
    if (_calcuFireClock > 0) {
        _calcuFireClock -= STATE_UPDATE_TIME_STEP;
    }
    else {
        [self schedualDDJ];
        
        _calcuFireClock = FIRE_CLOCK_INTERVAL;
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
    //NSLog(@"schedualed %ld DDJ", validDDJArr.count);
    [[RMSCoreCenter sharedCoreCenter] assignDDJ:validDDJArr];
}

- (NSArray<RMSDataDownloadJob *> *)produceDDJ
{
    NSMutableArray *ddrArr = [NSMutableArray arrayWithCapacity:self.ddrPool.allKeys.count];
    for (NSNumber *eosID in self.ddrPool.allKeys) {
        [ddrArr addObject:[self.ddrPool objectForKey:eosID]];
    }

    //NSLog(@"%@", self.ddrPool);
    
    [self.ddrPool removeAllObjects];
    
    RMSDataSize SUM_C_k_i_x = 0;
    for (RMSDataDownloadRequest *ddr in ddrArr) {
        SUM_C_k_i_x += ddr.dataSize;
    }
    
    //NSLog(@"%lf MB data from %ld DDR", SUM_C_k_i_x, ddrArr.count);
    
    //NSLog(@"begin schedual DDJ for %ld ddr", ddrArr.count);
    
    RMSSatelliteTime w_k_i_s, w_k_i_e;
    RMSSatelliteTime t_i_s, t_k_s, t_k_i_s, t_k_i_e;
    RMSDataSize B_k, C_u_x, C_k_i_x;
    RMSSatelliteTime T_k_i_x, t_k_i_x_s, t_k_i_x_e;
    NSMutableArray<RMSDataDownloadJob *> *ddjArr = [[NSMutableArray alloc] init];
    for (RMSDataRelaySatellite *drs in self.drsArray) {
        for (RMSDataDownloadRequest *ddr in ddrArr) {
            RMSTimeRange nextVisibleTimeWindow = [RMSMath nextVisibleTimeRangeBetweenEOS:ddr.eos andDRS:drs fromTime:self.systemTime];
            //NSLog(@"system time:%lf next visible time window:%lf-%lf", self.systemTime, nextVisibleTimeWindow.beginAt, nextVisibleTimeWindow.length);
            w_k_i_s = nextVisibleTimeWindow.beginAt;
            w_k_i_e = nextVisibleTimeWindow.beginAt + nextVisibleTimeWindow.length;
            t_i_s = drs.nearestServiceEnableTime;
            t_k_s = ddr.eos.nearestTransmissionEnableTime;
            t_k_i_s = MAX(t_i_s, t_k_s);
            t_k_i_s = MAX(t_k_i_s, w_k_i_s);
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
            job.TF = ddr.dataSize / SUM_C_k_i_x * ddrArr.count;
            
            [ddjArr addObject:job];
        }
    }
    
    //NSLog(@"schedualed %ld ddj from %ld ddr", ddjArr.count, ddrArr.count);
    
//    for (RMSDataDownloadJob *ddj in ddjArr) {
//        NSLog(@"PI:%lf", ddj.TF);
//    }
    
    return ddjArr;
}

- (void)calcuPI:(NSArray<RMSDataDownloadJob *> *)DDJArr
{
    //NSLog(@"begin calcu PI");
    
//    RMSDataSize SUM_C_k_i_x = 0;
//    for (RMSDataDownloadJob *job in DDJArr) {
//        SUM_C_k_i_x += job.dataSize;
//    }
    
    double TF_k_i_x, QOS_k_i_x, E_k_i_x, BU_k_i_x;
    RMSSatelliteTime t = _systemTime;
//    RMSSatelliteTime duration;
    //NSLog(@"(");
    for (RMSDataDownloadJob *job in DDJArr) {
        TF_k_i_x = job.TF;
        
        E_k_i_x = 0;
        for (RMSImageDataUnit *idu in job.iduArray) {
            E_k_i_x += idu.size / job.dataSize * (t - idu.producedTime);
        }
        
        QOS_k_i_x = pow(M_E, E_k_i_x / job.eos.orbitPeriod);
        
//        duration = job.endTime - job.startTime;
        BU_k_i_x = log2(MIN(job.eos.orbitPeriod / job.waitingTime + 1, 8));
        
        
        job.PI = TF_k_i_x * QOS_k_i_x * BU_k_i_x;
        
        //NSLog(@"Ex:%lf Qos:%lf",E_k_i_x, QOS_k_i_x);
        //NSLog(@"DataSize:%lf TF:%lf",job.dataSize, job.TF);
//        if (job.eos.uniqueID == 1) {
//            NSLog(@"PI-%lf TF-%lf Qos-%lf", job.PI, job.TF, QOS_k_i_x);
//        }
        
        //NSLog(@"EOS:%d PI:%lf TF:%lf QOS:%lf BU:%lf - Ex:%lf",job.eos.uniqueID, job.PI, TF_k_i_x, QOS_k_i_x, BU_k_i_x, E_k_i_x);
    }
    
    //NSLog(@")");
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
        [group sortUsingComparator:^NSComparisonResult(RMSDataDownloadJob * _Nonnull obj1, RMSDataDownloadJob * _Nonnull obj2) {
            if (obj1.PI < obj2.PI) {
                return NSOrderedDescending;
            }
            else if (obj1.PI == obj2.PI) {
                return NSOrderedSame;
            }
            
            return NSOrderedAscending;
        }];
        
        if (group.count > 0) {
            [validJobs addObject:[group firstObject]];
            [group removeObjectAtIndex:0];
        }
    }
    
    bool duplicated = true;
    NSUInteger duplicatedIndex;
    RMSDataDownloadJob *duplicatedJob01, *duplicatedJob02;
    NSMutableArray<RMSDataDownloadJob *> *jobGroup01, *jobGroup02;
    while (duplicated) {
        [validJobs sortUsingComparator:^NSComparisonResult(RMSDataDownloadJob * _Nonnull obj1, RMSDataDownloadJob * _Nonnull obj2) {
            if (obj1.eos.uniqueID < obj2.eos.uniqueID) {
                return NSOrderedAscending;
            }
            else if (obj1.eos.uniqueID == obj2.eos.uniqueID) {
                return NSOrderedSame;
            }
            
            return NSOrderedDescending;
        }];
        
        duplicated = false;
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
            
            jobGroup02 = [DDJGroups objectAtIndex:duplicatedJob02.drs.uniqueID];
            [validJobs removeObject:duplicatedJob02];
            if (jobGroup02.count > 0) {
                [validJobs addObject:[jobGroup02 firstObject]];
                [jobGroup02 removeObjectAtIndex:0];
            }
        }
        
        
//        if (duplicated) {
//            if (duplicatedJob02.PI > duplicatedJob01.PI) {
//                RMSDataDownloadJob *tmpJob = duplicatedJob01;
//                duplicatedJob01 = duplicatedJob02;
//                duplicatedJob02 = tmpJob;
//            }
//            
//            jobGroup01 = [DDJGroups objectAtIndex:duplicatedJob01.drs.uniqueID];
//            jobGroup02 = [DDJGroups objectAtIndex:duplicatedJob02.drs.uniqueID];
//            
//            if (jobGroup02.count > 0 || jobGroup01.count <= 0) {
//                [validJobs removeObject:duplicatedJob02];
//                if (jobGroup02.count > 0) {
//                    [validJobs addObject:[jobGroup02 firstObject]];
//                    [jobGroup02 removeObjectAtIndex:0];
//                }
//            }
//            else {
//                [validJobs removeObject:duplicatedJob01];
//                if (jobGroup01.count > 0) {
//                    [validJobs addObject:[jobGroup01 firstObject]];
//                    [jobGroup01 removeObjectAtIndex:0];
//                }
//            }
//        }
    }
    
    return validJobs;
}

@end
