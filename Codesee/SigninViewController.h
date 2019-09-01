//
//  SigninViewController.h
//  Codesee
//
//  Created by Leo Tang on 2019/1/16.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Google/SignIn.h>
#import <CodeseeSDK/CodeseeSDK.h>
#import "GoogleCloud.h"

NS_ASSUME_NONNULL_BEGIN

@interface SigninViewController : UIViewController <GIDSignInDelegate, GIDSignInUIDelegate>
@property (weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
- (IBAction)skipAction:(id)sender;

@property (nonatomic, strong) GoogleCloud *cloud;

@end

NS_ASSUME_NONNULL_END
