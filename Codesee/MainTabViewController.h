//
//  MainTabViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/16.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CodeseeSDK/CodeseeSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainTabViewController : UITabBarController <UITabBarControllerDelegate>
@property (nonatomic,strong) CodeseeMetadata *qrcodeMetadata;
- (void) processCompleted: (NSDictionary *) param;
@property (nonatomic,strong) UIActivityIndicatorView *indicator;
@end

NS_ASSUME_NONNULL_END
