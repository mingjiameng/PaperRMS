//
//  RMSCoreCenter.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSCoreCenter.h"
#import "RMSEarthObservationSatellite.h"
#import "RMSSysthesisCalculateCenter.h"
#import "RMSDataRelaySatellite.h"
#import "RMSDataDownloadJob.h"

@interface RMSCoreCenter ()

@property (nonatomic, strong, nonnull) NSArray<RMSEarthObservationSatellite *> *eosArray;
@property (nonatomic, strong, nonnull) RMSSysthesisCalculateCenter *calcuCenter;
@property (nonatomic, strong, nonnull) NSArray<RMSDataRelaySatellite *> *drsArray;

@end



@implementation RMSCoreCenter

+ (instancetype)sharedCoreCenter
{
    static dispatch_once_t onceToken;
    static RMSCoreCenter *center = nil;
    
    dispatch_once(&onceToken, ^{
        center = [[RMSCoreCenter alloc] init];
    });
    
    return center;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self readInEos];
        [self readInDrs];
        self.calcuCenter = [RMSSysthesisCalculateCenter sharedSysthesisCalculateCenter];
        self.calcuCenter.drsArray = self.drsArray;
    }
    
    return self;
}

- (void)readInEos
{
    NSString *eosParamFile = @"eos_param_4_orbit_plane.txt";
    NSString *eosParamFilePath = [FILE_INPUT_PATH_PREFIX_STRING stringByAppendingString:eosParamFile];
    FILE *eosParam = fopen([eosParamFilePath cStringUsingEncoding:NSUTF8StringEncoding], "r");
    assert(eosParam != NULL);
    
    int n;
    double raan, aop, oi, sma, e, ta;
    //int retrograde;
    int satelliteID;
    fscanf(eosParam, "%d", &n);
    NSLog(@"%d eos", n);
    NSMutableArray *eosSet = [[NSMutableArray alloc] initWithCapacity:n];
    while (n--) {
        fscanf(eosParam, "%d", &satelliteID);
        RMSEarthObservationSatellite *newEos = [[RMSEarthObservationSatellite alloc] initWithSatelliteID:satelliteID];
        
        fscanf(eosParam, "%lf %lf %lf %lf %lf %lf", &raan, &aop, &oi, &sma, &e, &ta);
        RMSSatelliteOrbit orbit;
        orbit.raan = raan;
        orbit.aop = aop;
        orbit.oi = oi;
        orbit.sma = sma;
        orbit.e = e;
        orbit.ta = ta;
        orbit.retrograde = true;
        newEos.orbit = orbit;
        
        newEos.bandwidth = 650.0f;
        
        [eosSet addObject:newEos];
    }
    
    self.eosArray = eosSet;
    
    fclose(eosParam);
}

- (void)readInDrs
{
    NSString *drsParamFile = @"drs_param.txt";
    NSString *drsParamFilePath = [FILE_INPUT_PATH_PREFIX_STRING stringByAppendingString:drsParamFile];
    FILE *drsParam = fopen([drsParamFilePath cStringUsingEncoding:NSUTF8StringEncoding], "r");
    assert(drsParam != NULL);
    
    int m;
    double raan, aop, oi, sma, e, ta;
    int satelliteID;
    fscanf(drsParam, "%d", &m);
    NSLog(@"%d drs", m);
    NSMutableArray *drsSet = [[NSMutableArray alloc] initWithCapacity:m];
    while (m--) {
        RMSDataRelaySatellite *newDrs = [[RMSDataRelaySatellite alloc] init];
        fscanf(drsParam, "%d", &satelliteID);
        NSLog(@"drsID %d", satelliteID);
        newDrs.uniqueID = satelliteID;
        
        fscanf(drsParam, "%lf %lf %lf %lf %lf %lf", &raan, &aop, &oi, &sma, &e, &ta);
        RMSSatelliteOrbit orbit;
        orbit.raan = raan;
        orbit.aop = aop;
        orbit.oi = oi;
        orbit.sma = sma;
        orbit.e = e;
        orbit.ta = ta;
        orbit.retrograde = false;
        newDrs.orbit = orbit;
        
        newDrs.bandwidth = 650.0f;
        
        [drsSet addObject:newDrs];
    }
    
    self.drsArray = drsSet;
    
    fclose(drsParam); 
}

- (void)fire
{
    double time = SIMULATION_DURATION;
    while (time > 0) {
        for (RMSEarthObservationSatellite *eos in self.eosArray) {
            [eos updateState];
        }
        
        for (RMSDataRelaySatellite *drs in self.drsArray) {
            [drs updateState];
        }
        
        [self.calcuCenter updateState];
        
        time -= STATE_UPDATE_TIME_STEP;
    }
    
    for (RMSEarthObservationSatellite *eos in self.eosArray) {
        [eos stop];
    }
    
    for (RMSDataRelaySatellite *drs in self.drsArray) {
        [drs stop];
    }
}

- (void)assignDDJ:(NSArray<RMSDataDownloadJob *> *)DDJArr
{
    for (RMSDataDownloadJob *job in DDJArr) {
        [job.drs schedualDDJ:job];
        [job.eos schedualDDJ:job];
    }
}

@end
