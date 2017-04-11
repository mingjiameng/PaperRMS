//
//  RMSSysthesisCalculateCenter.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMSEarthObservationSatellite.h"
#import "RMSDataDownloadRequest.h"
#import "RMSDataRelaySatellite.h"

@interface RMSSysthesisCalculateCenter : NSObject

@property (nonatomic, weak, nullable) NSArray<RMSDataRelaySatellite *> *drsArray;


+ (nonnull instancetype)sharedSysthesisCalculateCenter;


- (void)updateState;
- (void)dataDownloadRequest:(nonnull RMSDataDownloadRequest *)request;



@end
