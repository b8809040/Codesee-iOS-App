//
//  SettingTableViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/21.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainTabViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingTableViewController : UITableViewController
@property (nonatomic, weak) MainTabViewController *viewController;
@end

NS_ASSUME_NONNULL_END
