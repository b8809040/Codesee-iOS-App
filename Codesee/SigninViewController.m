//
//  SigninViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/16.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "SigninViewController.h"
#import <GTLRDrive.h>
#import "MainTabViewController.h"

SigninViewController *signinViewController; // FIXME: workaround

@interface SigninViewController ()

@end

@implementation SigninViewController

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    signinViewController = self; // FIXME: workaround
    BOOL isFTI = NO;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (!([fileManager fileExistsAtPath:[CodeseeUtilities getDocPath: @""] isDirectory:&isDir] && isDir)) {
        [fileManager createDirectoryAtPath:[CodeseeUtilities getDocPath: @""] withIntermediateDirectories:YES attributes:nil error: &error];
        [fileManager createDirectoryAtPath:[CodeseeUtilities getDocPath: @"MyCodesee"] withIntermediateDirectories:YES attributes:nil error: &error];
        isFTI = YES;
        if(error != nil) {
            NSLog(@"Default folder create fail");
        }
    }

    if(isFTI) {
        error = nil;
        [fileManager copyItemAtPath: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"codesee.local.db3"] toPath: [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.local.db3"]] error: &error];
        if(error != nil) {
            NSLog(@"Duplicate codesee.local.db3 fail");
        }
        error = nil;
        [fileManager copyItemAtPath: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"codesee.fts.db3"] toPath: [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.fts.db3"]] error: &error];
        if(error != nil) {
            NSLog(@"Duplicate codesee.fts.db3 fail");
        }
    }

    CodeseeDB *database = [[CodeseeDB alloc] init];
    
    NSString *databaseFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.local.db3"]];
    
    if([database open: databaseFile] == NO) {
        NSLog(@"database open fail");
    }

    [database close];

    GIDSignIn* signIn = [GIDSignIn sharedInstance];
    signIn.uiDelegate = self;
    signIn.delegate = self;
    signIn.scopes = [NSArray arrayWithObjects:kGTLRAuthScopeDrive, nil];
    [signIn signInSilently];

    self.cloud = [[GoogleCloud alloc] init];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    if(error == nil) {
        // Perform any operations on signed in user here.
        NSLog(@"full name=%@", user.profile.name);

        self.cloud.service.authorizer = user.authentication.fetcherAuthorizer;
        [self.cloud login: user.profile.email];

        // Sync
        //[self.cloud sync];

        // Switch to main function
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainTabViewController *mainTabViewVC = [storyboard instantiateViewControllerWithIdentifier:@"main-tab-view"];
        [self presentViewController:mainTabViewVC animated:YES completion:nil];
    } else {
        [self showAlert: NSLocalizedString(@"Authenticationerror",nil) message:error.localizedDescription];
    }
}

- (IBAction)skipAction:(id)sender {
    // Switch to main function
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainTabViewController *mainTabViewVC = [storyboard instantiateViewControllerWithIdentifier:@"main-tab-view"];
    [self presentViewController:mainTabViewVC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
