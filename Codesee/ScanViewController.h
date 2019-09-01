//
//  ScanViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/18.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MainTabViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) MainTabViewController *viewController;
@end

NS_ASSUME_NONNULL_END
