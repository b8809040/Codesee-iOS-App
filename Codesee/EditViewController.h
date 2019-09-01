//
//  EditViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/19.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainTabViewController.h"
#import "SRPhotoBrowser/SRPictureBrowser.h"
#import "SRPhotoBrowser/SRPictureModel.h"
#import <QBImagePickerController/QBImagePickerController.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditViewController : UIViewController <SRPictureBrowserDelegate, QBImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, weak) MainTabViewController *viewController;
@end

NS_ASSUME_NONNULL_END
