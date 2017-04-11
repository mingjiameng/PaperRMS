//
//  RMSSatellite.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct {
    double raan; // 右升交点赤经
    double aop; // 近地点幅角
    double oi; // 轨道倾角
    double sma; // 长半轴 千米
    double e; // 离心率
    double ta; // 真近点角
    bool retrograde; // 是否逆行
}RMSSatelliteOrbit;

@interface RMSSatellite : NSObject

@property (nonatomic) RMSSatelliteID uniqueID;
@property (nonatomic) RMSSatelliteOrbit orbit;
@property (nonatomic) RMSSatelliteTime systemTime;

@property (nonatomic) RMSDataSize bandwidth;

// 以下参数衍生自轨道参数
@property (nonatomic) RMSRadian orbitRadianSpeed;
@property (nonatomic) RMSSatelliteTime orbitPeriod;

- (void)updateState;
- (void)stop;

@end
