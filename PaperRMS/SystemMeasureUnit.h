//
//  SystemMeasureUnit.h
//  PaperRMS
//
//  Created by 梁志鹏 on 2017/3/30.
//  Copyright © 2017年 overcode. All rights reserved.
//

#ifndef SystemMeasureUnit_h
#define SystemMeasureUnit_h

typedef double RMSSatelliteTime; // S
typedef double RMSDataSize; // MB
typedef int RMSSatelliteID;
typedef double RMSAngle;
typedef double RMSRadian; // 单位:弧度
typedef double RMSPriorityIndex;

typedef struct _RMSTimeRange {
    RMSSatelliteTime beginAt;
    RMSSatelliteTime length;
}RMSTimeRange;


#define STATE_UPDATE_TIME_STEP 1.0f
#define EARTH_AUTO_ROTATION_ANGLE_SPEED 4.167e-3 // 自转角速度 单位：角度
#define KEPLER_STATIC 3.9861e5
#define DRS_SWITCH_TIME 180.0f
#define EOS_SWITCH_TIME 180.0f
#define LONGEST_SWITCH_ON_TIME 600.0f
#define SIMULATION_DURATION 282968 // 50个轨道周期

#define FILE_OUTPUT_PATH_PREFIX_STRING @"/Users/zkey/Desktop/science/paper_allocation_algorithm/output/"
#define FILE_INPUT_PATH_PREFIX_STRING @"/Users/zkey/Desktop/science/paper_allocation_algorithm/input/"

#endif /* SystemMeasureUnit_h */
