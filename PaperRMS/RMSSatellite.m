//
//  RMSSatellite.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSSatellite.h"

#import "RMSMath.h"


@implementation RMSSatellite

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.systemTime = 0;
    }
    
    return self;
}

- (void)setOrbit:(RMSSatelliteOrbit)orbit
{
    _orbit = orbit;
    _orbitPeriod = [RMSMath orbitPeriodOfSatelliteOrbit:orbit];
    _orbitRadianSpeed = 2 * M_PI / _orbitPeriod;
}


- (void)updateState
{
    self.systemTime += STATE_UPDATE_TIME_STEP;
}

- (void)stop
{
    
}

@end
