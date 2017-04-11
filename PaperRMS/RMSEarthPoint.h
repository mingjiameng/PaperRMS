//
//  RMSEarthPoint.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/4/6.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMSEarthPoint : NSObject

@property (nonatomic) double longitude;
@property (nonatomic) double latitude;

- (nonnull instancetype)initWithLongitude:(double)longitude andLatitude:(double)latitude;

@end
