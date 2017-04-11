//
//  RMSDataDownloadJob.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/4/6.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMSEarthObservationSatellite.h"
#import "RMSDataRelaySatellite.h"

@interface RMSDataDownloadJob : NSObject

@property (nonatomic, weak, nullable) RMSEarthObservationSatellite *eos;
@property (nonatomic, weak, nullable) RMSDataRelaySatellite *drs;
@property RMSSatelliteTime startTime;
@property RMSSatelliteTime endTime;
@property RMSSatelliteTime waitingTime;

@property RMSPriorityIndex PI;
@property RMSDataSize dataSize;

@property (nonatomic, strong, nonnull) NSArray<RMSImageDataUnit *> *iduArray; // 要传输的IDU

@end
