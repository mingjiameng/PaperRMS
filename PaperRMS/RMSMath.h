//
//  RMSMath.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMSSatellite.h"
@class RMSEarthObservationSatellite;
@class RMSDataRelaySatellite;

@interface RMSMath : NSObject

+ (RMSSatelliteTime)orbitPeriodOfSatelliteOrbit:(RMSSatelliteOrbit)orbit;
+ (RMSTimeRange)nextVisibleTimeRangeBetweenEOS:(RMSEarthObservationSatellite *)eos andDRS:(RMSDataRelaySatellite *)drs inTimeRange:(RMSTimeRange)validTimeRange;

@end
