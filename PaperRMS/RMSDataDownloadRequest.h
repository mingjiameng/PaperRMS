//
//  RMSDataDownloadRequest.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMSEarthObservationSatellite.h"
#import "RMSImageDataUnit.h"


@interface RMSDataDownloadRequest : NSObject

@property (nonatomic, strong, nonnull) RMSEarthObservationSatellite *eos;
@property (nonatomic, copy, nonnull) NSArray<RMSImageDataUnit *> *iduArray;
@property RMSDataSize dataSize;

@end
