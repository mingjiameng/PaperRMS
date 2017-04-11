//
//  RMSDataRelaySatellite.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMSSatellite.h"

@class RMSDataDownloadJob;

@interface RMSDataRelaySatellite : RMSSatellite

@property (nonatomic, readonly) RMSSatelliteTime nearestServiceEnableTime;

- (void)schedualDDJ:(nonnull RMSDataDownloadJob *)ddj;

@end
