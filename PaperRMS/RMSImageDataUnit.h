//
//  RMSImageDataUnit.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMSImageDataUnit : NSObject

@property RMSSatelliteTime producedTime; // IDU 产生的时间
@property RMSDataSize size; // IDU 数据量大小

@end
