//
//  RMSEarthObservationSatellite.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSSatellite.h"

@class RMSDataDownloadJob;

@interface RMSEarthObservationSatellite : RMSSatellite

@property (nonatomic) RMSSatelliteTime nearestTransmissionEnableTime;

- (void)schedualDDJ:(nonnull RMSDataDownloadJob *)ddj;

@end
