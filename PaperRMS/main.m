//
//  main.m
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/28.
//  Copyright © 2017年 overcode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMSCoreCenter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        RMSCoreCenter *center = [[RMSCoreCenter alloc] init];
        [center fire];
        
    }
    return 0;
}
