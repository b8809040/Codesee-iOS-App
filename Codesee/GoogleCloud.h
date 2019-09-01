//
//  GoogleCloud.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/18.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CodeseeSDK/CodeseeSDK.h>
#import <GTLRDrive.h>

NS_ASSUME_NONNULL_BEGIN

@interface GoogleCloud : CodeseeCloud
@property (nonatomic,strong) GTLRDriveService *service;
@end

NS_ASSUME_NONNULL_END
