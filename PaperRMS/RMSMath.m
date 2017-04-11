//
//  RMSMath.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSMath.h"

#import "RMSEarthPoint.h"
#import "RMSEarthObservationSatellite.h"
#import "RMSDataRelaySatellite.h"

@implementation RMSMath

+ (RMSTimeRange)nextVisibleTimeRangeBetweenEOS:(RMSEarthObservationSatellite *)eos andDRS:(RMSDataRelaySatellite *)drs fromTime:(RMSSatelliteTime)time
{
    RMSEarthPoint *userSubPoint = [self subSatellitePoint:eos atTime:time];
    RMSEarthPoint *geoSubPoint = [self subSatellitePoint:drs atTime:time];
    
    RMSAngle longitudeDis = fabs(userSubPoint.longitude - geoSubPoint.longitude);
    if (!eos.orbit.retrograde) {
        longitudeDis = 360.0 - longitudeDis;
    }
    
    RMSAngle subPointLongitudeSpeed = 360.0 / eos.orbitPeriod - EARTH_AUTO_ROTATION_ANGLE_SPEED;
    RMSSatelliteTime td = longitudeDis / subPointLongitudeSpeed + time;
    RMSSatelliteTime duration = 160 / subPointLongitudeSpeed; // 星下点+- 80度可见
    
    RMSTimeRange visibleTimeRange;
    visibleTimeRange.beginAt = MAX(td - duration / 2, time);
    visibleTimeRange.length = MIN(duration, td + duration / 2 - time);
    
    //NSLog(@"visible time range begin at:%lf length:%lf", validTimeRange.beginAt, validTimeRange.length);
    
    return visibleTimeRange;
}

+ (RMSEarthPoint *)subSatellitePoint:(RMSSatellite *)satellite atTime:(RMSSatelliteTime)time
{
    double theta0 = satellite.orbit.ta + satellite.orbit.aop;
    double theta = theta0 + satellite.orbitRadianSpeed * time; // 单位：弧度
    //NSLog(@"theta before scale:%lf", theta);
    double theta_scale = floor((theta + M_PI) / (2 * M_PI));
    //NSLog(@"theta scale:%lf", theta_scale);
    theta -= theta_scale * 2 * M_PI;
    
    double lambda0 = satellite.orbit.raan / M_PI * 180;
    double earth_rotation_angle = EARTH_AUTO_ROTATION_ANGLE_SPEED * time;
    double lambda = lambda0 + atan(cos(satellite.orbit.oi) * tan(theta)) / M_PI * 180 - earth_rotation_angle;
    if (theta < - M_PI_2) {
        lambda += (satellite.orbit.retrograde) ? (180) : (-180);
    }
    else if (theta > M_PI_2) {
        lambda += (satellite.orbit.retrograde) ? (-180) : (180);
    }
    
    double lambda_scale = floor((lambda + 180) / 360);
    lambda -= lambda_scale * 360;
    
    double fi = asin(sin(satellite.orbit.oi) * sin(theta));
    fi = fi / M_PI * 180;
    
    RMSEarthPoint *point = [[RMSEarthPoint alloc] initWithLongitude:lambda andLatitude:fi];
    
    return point;
}

+ (RMSSatelliteTime)orbitPeriodOfSatelliteOrbit:(RMSSatelliteOrbit)orbit
{
    RMSSatelliteTime period = 2 * M_PI * sqrt(pow(orbit.sma, 3) / KEPLER_STATIC);
    
    return period;
}

@end
