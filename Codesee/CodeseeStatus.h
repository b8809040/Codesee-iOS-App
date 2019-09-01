//
//  CodeseeStatus.h
//  Codesee
//
//  Created by Leo Tang on 2018/4/19.
//  Copyright © 2018年 Leo Tang. All rights reserved.
//

#ifndef CodeseeStatus_h
#define CodeseeStatus_h

typedef enum _CodeseeStatus {
    CodeseeStatusInit = 0,
    CodeseeStatusScanning,
    CodeseeStatusEditing
} CodeseeStatus;

typedef enum _CodeseeEvent {
    CodeseeEventScanFinish = 0,
    CodeseeEventScanRetry,
    CodeseeEventScanCancel,
    CodeseeEventEditFinish,
    CodeseeEventEditCancel,
    CodeseeEventEditUpdate
} CodeseeEvent;

#endif /* CodeseeStatus_h */
