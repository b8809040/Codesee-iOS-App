//
//  ImagelistTableViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/20.
//  Copyright © 2019 Leo Tang. All rights reserved.
//
// Using https://github.com/TheNiks/GalleryView

#import <UIKit/UIKit.h>
#import "MainTabViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImagelistTableViewController : UITableViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) MainTabViewController *viewController;
@end

NS_ASSUME_NONNULL_END
