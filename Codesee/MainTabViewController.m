//
//  MainTabViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/16.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "MainTabViewController.h"
#import "ScanViewController.h"
#import "EditViewController.h"
#import "ImagelistTableViewController.h"
#import "SettingTableViewController.h"
#import "CodeseeStatus.h"
#import "RDPopup.h"

@interface MainTabViewController () <RDPopupProtocol>
{
    CodeseeStatus status;
    CodeseeStatus previousStatus;
    ScanViewController *scanViewController;
    EditViewController *editViewController;
    ImagelistTableViewController *imagelistTableViewController;
    SettingTableViewController *settingTableViewController;
    NSString *capturedImageFilename;
    NSString *databaseFile;
    RDPopup *popup;
    NSString *ftsFile;
}
@end

@implementation MainTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    previousStatus = CodeseeStatusInit;
    status = CodeseeStatusScanning;
    self.delegate = self;  // for UITabBarController

    NSArray *viewControllers = [[[self viewControllers] objectAtIndex:0] viewControllers];
    self->scanViewController = [viewControllers objectAtIndex: 0];
    self->scanViewController.viewController = self;

    viewControllers = [[[self viewControllers] objectAtIndex:1] viewControllers];
    self->imagelistTableViewController = [viewControllers objectAtIndex: 0];
    self->imagelistTableViewController.viewController = self;

    viewControllers = [[[self viewControllers] objectAtIndex:2] viewControllers];
    self->settingTableViewController = [viewControllers objectAtIndex: 0];
    self->settingTableViewController.viewController = self;

    [self setSelectedIndex: 0]; // default scan view

    self->databaseFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.local.db3"]];

    self->ftsFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.fts.db3"]];

    capturedImageFilename = nil;
    // Setup RDPopup dialog
    popup = [[RDPopup alloc]initOnView:self.view];
    popup.delegate = self;
    popup.title = NSLocalizedString(@"NewQRcode",nil);
    popup.message = @"";
    popup.cancelButtonTitle = NSLocalizedString(@"Cancel",nil);
    popup.otherButtonTitle = NSLocalizedString(@"Done",nil);
    popup.buttonRadius = 10;
    popup.dismissOnBackgroundTap = YES;
    // Setup daisy waiting animation
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame: self.view.bounds];
    self.indicator.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.indicator.color = [UIColor colorWithRed:0.60 green:0.59 blue:0.59 alpha:1.0];
    [self.indicator setUserInteractionEnabled:NO];
    [self.view addSubview: self.indicator];
}

- (void)viewDidDisappear:(BOOL)animated {
}

-(void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if(tabBarController.selectedIndex == 0) {
        // switch to scan view
    } else if (tabBarController.selectedIndex == 1) {
        // switch to image list view
        // show daisy
        [self.indicator startAnimating];
    } else if (tabBarController.selectedIndex == 2) {
        // switch to settings view
        // show daisy
        [self.indicator startAnimating];
    }
}

// Handle event from different views
// Use state machine to control the views

- (void) processCompleted: (NSDictionary *) param
{
    CodeseeEvent event = (CodeseeEvent) [[param objectForKey:@"event"] intValue];

    if(status == CodeseeStatusScanning) {
        if(event == CodeseeEventScanRetry) {
            // Do nothing and keep scanning
            [self->scanViewController viewDidAppear:TRUE]; // FIXME: workaround
            // Update status
            previousStatus = status;
            status = CodeseeStatusScanning;
        } else if(event == CodeseeEventScanFinish) {
            // QR code scanned (Maybe new or old) and switch to edit view
            NSString *qrcode = (NSString *) param[@"qrcode"];
            UIImage *qrcodeImage = (UIImage *) param[@"qrcode_image"];
            // Create or open QR code metadata
            BOOL shouldArchive = NO;
            CodeseeDBAction metadataDBAction = CodeseeDBCreate;
            NSError *error;
            NSData *data;
            NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
            [fileManager createDirectoryAtPath:qrcodeFolder withIntermediateDirectories:YES attributes:nil error: &error];
            NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
            if ([fileManager fileExistsAtPath:qrcodeMetadataFile] == YES){
                // Old QR code
                data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
                self.qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
                if(error != nil) {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                metadataDBAction = CodeseeDBUpdate;
            } else {
                // New QR code
                self.qrcodeMetadata = [[CodeseeMetadata alloc] init];
                metadataDBAction = CodeseeDBCreate;
                [self.qrcodeMetadata setData: @"qrcode" Value: qrcode];
                // Keep the date of this new QR code
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"yyyy/MM/dd/HH"];
                NSString *qrcodeDate = [NSString stringWithFormat: @"%@", [dateFormat stringFromDate: [NSDate date]]];
                [self.qrcodeMetadata setData: @"qrcode_date" Value: qrcodeDate];
                // Popup dialog in edit view for the descrption of the new QR code
                popup.message = [[NSString alloc] initWithFormat: @"Date:%@--%@", qrcodeDate, @"MyCodesee"];
                [popup showPopup];
                // Should archive QR code metadata since there are new metadata
                shouldArchive = YES;
                // Full Text Search (FTS) new record
                CodeseeFTS *fts = [CodeseeFTS new];
                if([fts open: ftsFile] == NO) {
                    NSLog(@"fts open file error");
                }
                [fts addNote: qrcode note:@""];
                [fts close];
                // log
                // Keep QR code metadata event in journal (Maybe create or update)
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: qrcode Action: CodeseeDBCreateFolder];
                [database close];
            }
            // Save the scanned QR code image (searching box by objects)
            NSString *qrcodeImageFilename = [NSString stringWithFormat:@"%@.jpg", qrcode];
            NSString *qrcodeImageFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeImageFilename];
            if ([fileManager fileExistsAtPath:qrcodeImageFile] == NO){
                // Save QR code image as jpg
                NSData *qrcodeImageData = UIImageJPEGRepresentation(qrcodeImage, 1.0);
                if([qrcodeImageData writeToFile: qrcodeImageFile atomically:YES] == NO) {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                // Put new QR code image file name in QR code metadata
                [self.qrcodeMetadata addImage: qrcodeImageFilename];
                // Keep new QR code image event in journal
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeImageFilename] Action: CodeseeDBCreate];
                [database close];
                // Should archive QR code metadata since it's dirty
                shouldArchive = YES;
            }
            // Put new image file name in QR code metadata if there are new image captured in previous state
            if(self->capturedImageFilename != nil) {
                [self.qrcodeMetadata addImage: self->capturedImageFilename];
                // Keep new captured image event in journal
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, self->capturedImageFilename] Action: CodeseeDBCreate];
                [database close];
                // Clean
                self->capturedImageFilename = nil;
                // Should archive QR code metadata since it's dirty
                shouldArchive = YES;
            }
            // Archive QR code metadata
            if(shouldArchive == YES) {
                data = [NSKeyedArchiver archivedDataWithRootObject:self.qrcodeMetadata requiringSecureCoding: NO error:&error];
                if(error != nil) {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                if([data writeToFile: qrcodeMetadataFile atomically:YES] == NO) {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                // Keep QR code metadata event in journal (Maybe create or update)
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: metadataDBAction];
                [database close];
            }
            // Switch to edit view
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];    // Main is the default name
            self->editViewController = [storyboard instantiateViewControllerWithIdentifier:@"edit-view"];
            self->editViewController.viewController = self;
            [[self->scanViewController navigationController] pushViewController: self->editViewController animated:YES];
            // Update status
            previousStatus = status;
            status = CodeseeStatusEditing;
        }
    } else if(status == CodeseeStatusEditing) {
        if(event == CodeseeEventEditCancel || event == CodeseeEventEditFinish) {
            // Switch to scan view
            //self.selectedViewController = [self.viewControllers objectAtIndex:0];
            [[self->scanViewController navigationController] popViewControllerAnimated:YES];
            // Update status
            previousStatus = status;
            status = CodeseeStatusScanning;
        } else if(event == CodeseeEventEditUpdate) {
            // No state change and just update the QR code metadata
            NSString *newNote = [param objectForKey:@"add_note"];
            NSString *removedImageFilename = [param objectForKey:@"remove_img"];
            NSArray *importedImageArray = [param objectForKey:@"add_img"];
            if(newNote != nil) {
                NSString *oldNote = [self.qrcodeMetadata getData:@"note"];
                if([newNote isEqualToString: oldNote] == NO) {
                    NSLog(@"new note:%@; old note:%@", newNote, oldNote);
                    [self.qrcodeMetadata setData:@"note" Value:newNote];
                    // Archive QR code metadata
                    NSString *qrcode = [self.qrcodeMetadata getData:@"qrcode"];
                    NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
                    NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
                    NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
                    NSError *error;
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self.qrcodeMetadata requiringSecureCoding: NO error:&error];
                    if(error == nil && data != nil) {
                        [data writeToFile: qrcodeMetadataFile atomically:YES];
                    } else {
                        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                    }
                    // Full Text Search (FTS) update record
                    CodeseeFTS *fts = [CodeseeFTS new];
                    if([fts open: ftsFile] == NO) {
                        NSLog(@"fts open file error");
                    }
                    [fts updateNote: qrcode note: newNote];
                    [fts close];
                    // Keep QR code metadata update event in journal
                    CodeseeDB *database = [CodeseeDB new];
                    [database open: self->databaseFile];
                    [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
                    [database log: [NSString stringWithFormat:@"codesee.fts.db3"] Action: CodeseeDBUpdate];
                    [database close];
                }
            }
            if(removedImageFilename != nil) {
                [self.qrcodeMetadata removeImage: removedImageFilename];
                // Archive QR code metadata
                NSString *qrcode = [self.qrcodeMetadata getData:@"qrcode"];
                NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
                NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
                NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
                NSError *error;
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self.qrcodeMetadata requiringSecureCoding: NO error:&error];
                if(error == nil && data != nil) {
                    [data writeToFile: qrcodeMetadataFile atomically:YES];
                } else {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                // Keep QR code metadata update event in journal (Maybe create or update)
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
                // Remove image from QR code metadata
                NSString *removedImageFile = [qrcodeFolder stringByAppendingPathComponent: removedImageFilename];
                // Delete image
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:removedImageFile]){
                    NSLog(@"remove file %@", removedImageFilename);
                    [fileManager removeItemAtPath: removedImageFile error:&error];
                } else {
                    NSLog(@"file %@ not found", removedImageFilename);
                }
                // Keep image removed event in journal
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, removedImageFilename] Action: CodeseeDBDelete];
                [database close];
            }
            for(NSString *filename in importedImageArray ){
                [self.qrcodeMetadata addImage: filename];
                // Archive QR code metadata
                NSString *qrcode = [self.qrcodeMetadata getData:@"qrcode"];
                NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
                NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
                NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
                NSError *error;
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self.qrcodeMetadata requiringSecureCoding: NO error:&error];
                if(error == nil && data != nil) {
                    [data writeToFile: qrcodeMetadataFile atomically:YES];
                } else {
                    NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                }
                // Keep QR code metadata update event in journal
                CodeseeDB *database = [CodeseeDB new];
                [database open: self->databaseFile];
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
                // Keep image create event in journal
                [database log: [NSString stringWithFormat:@"%@/%@", qrcode, filename] Action: CodeseeDBCreate];
                [database close];
            }
            // Update edit view
            [self->editViewController viewDidAppear:TRUE];
        }
    }
    
}

- (void)otherButtonAction:(CustomPopup *)popupView button:(UIButton *)button {
    // Get QR code metadata
    NSString *qrcode = [self.qrcodeMetadata getData: @"qrcode"];
    NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
    NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
    NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
    // Check if user change the default title
    NSString *defaultTitle =  [[NSString alloc] initWithFormat: @"Date:%@--%@", [self.qrcodeMetadata getData: @"qrcode_date"], @"MyCodesee"];
    NSLog(@"popup message: %@", popup.message);
    if([popup.message isEqualToString: defaultTitle]) {
        [popup hidePopup];
        return;
    }
    // Save new title
    [self.qrcodeMetadata setData: @"description" Value: popup.message];
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self.qrcodeMetadata requiringSecureCoding: NO error:&error];
    if(error != nil) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    if([data writeToFile: qrcodeMetadataFile atomically:YES] == NO) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    // Keep QR code metadata event in journal (Maybe create or update)
    CodeseeDB *database = [CodeseeDB new];
    [database open: self->databaseFile];
    [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
    [database close];
    button.backgroundColor = [UIColor blueColor];
    [popup hidePopup];
}

- (void)cancelButtonAction:(CustomPopup *)popupView button:(UIButton *)button {
    [popup hidePopup];
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
