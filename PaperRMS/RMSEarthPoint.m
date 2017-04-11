//
//  RMSEarthPoint.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/4/6.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import "RMSEarthPoint.h"

@implementation RMSEarthPoint

- (instancetype)initWithLongitude:(double)longitude andLatitude:(double)latitude
{
    self = [super init];
    
    if (self) {
        self.longitude = longitude;
        self.latitude = latitude;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<longitude, latitude> <%lf, %lf>", self.longitude, self.latitude];
}

@end
