//
//  EditViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/19.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "EditViewController.h"
#import <CodeseeSDK/CodeseeSDK.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "CodeseeStatus.h"
#import "RDPopup.h"

typedef enum _EditViewTool {
    EditViewToolImport = 0,
    EditViewToolCamera,
    EditViewToolNote,
    EditViewToolNum
} EditViewTool;

@interface EditViewController () <RDPopupProtocol>
{
    NSMutableArray *imageArray;
    NSMutableArray *imageViewFrames;
    NSDate *now;
    UIImagePickerController *imagePicker;
    NSString *qrcode;
    RDPopup *popup;
}
@end

@implementation EditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Setup RDPopup dialog
    popup = [[RDPopup alloc]initOnView:self.view];
    popup.delegate = self;
    popup.title = NSLocalizedString(@"Note",nil);
    popup.cancelButtonTitle = NSLocalizedString(@"Cancel",nil);
    popup.otherButtonTitle = NSLocalizedString(@"Done",nil);
    popup.buttonRadius = 10;
    popup.dismissOnBackgroundTap = YES;
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Do any additional setup after loading the view.
    //
    self->qrcode = [self.viewController.qrcodeMetadata getData: @"qrcode"];
    NSArray *userFolders = [self listFolderAtPath: [CodeseeUtilities getDocPath: @""]];
    self->imageArray = [[NSMutableArray alloc] init];
    for(NSString *folderName in userFolders) {
        NSError *error;
        NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", self->qrcode];
        NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: folderName] , self->qrcode];
        NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
        NSData *data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
        CodeseeMetadata *qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
        NSArray *tmpImageArray = [qrcodeMetadata getImages];
        for(NSString *filename in tmpImageArray) {
            NSString *file = [qrcodeFolder stringByAppendingPathComponent: [NSString stringWithFormat:@"%@", filename]];
            NSDictionary *item = @{@"owner":folderName,@"file":file};
            [self->imageArray addObject: item];
        }
    }
    //
    UIScrollView *container = [[UIScrollView alloc] init];
    container.backgroundColor = [UIColor whiteColor];
    container.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
    container.center = self.view.center;

    CGFloat margin = 10;
    CGFloat imageViewWH = (self.view.frame.size.width - 4 * margin) / 3;

    container.contentSize = CGSizeMake(self.view.frame.size.width, imageViewWH*((self->imageArray.count/3) + 2));

    [self.view addSubview: container];

    UIImageView *firstImageView = nil;
    for (int i = 0 ; i < self->imageArray.count + EditViewToolNum; i++) {
        int col = i % 3;
        int row = i / 3;
        UIImageView *imageView = [[UIImageView alloc] init];
        if(i == EditViewToolNum) {
            firstImageView = imageView;
        }
        imageView.tag = i;
        CGFloat imageViewX = margin + col * (margin + imageViewWH);
        CGFloat imageViewY = margin + row * (margin + imageViewWH);
        imageView.frame = CGRectMake(imageViewX, imageViewY, imageViewWH, imageViewWH);
        [self->imageViewFrames addObject:[NSValue valueWithCGRect:imageView.frame]];
        if(i == EditViewToolNote) {
            imageView.image = [UIImage imageNamed:@"edit-view-note-button"];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(noteTapAction:)];
            [imageView addGestureRecognizer:tapGestureRecognizer];
        } else if(i == EditViewToolCamera) {
            imageView.image = [UIImage imageNamed:@"edit-view-camera-button"];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraTapAction:)];
            [imageView addGestureRecognizer:tapGestureRecognizer];
        } else if (i == EditViewToolImport) {
            imageView.image = [UIImage imageNamed:@"setting-view-add-button"];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePickerTapAction:)];
            [imageView addGestureRecognizer:tapGestureRecognizer];
        } else {
            imageView.image = [UIImage imageNamed: [NSString stringWithFormat:@"%@", [self->imageArray objectAtIndex:i-EditViewToolNum][@"file"]]];
            imageView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapAction:)];
            [imageView addGestureRecognizer:tapGestureRecognizer];
            UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imageLongPressAction:)];
            [imageView addGestureRecognizer:longPressRecognizer];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.backgroundColor = [UIColor colorWithRed:1.00 green:0.72 blue:0.00 alpha:1.0];
        }
        [container addSubview: imageView];
    }
    // Show the first image
    //[self showPicture: firstImageView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //
    NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventEditFinish]};
    //
    [self.viewController processCompleted: param];
}

- (void)imageTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    UIImageView *tapedImageView = (UIImageView *)tapGestureRecognizer.view;
    [self showPicture: tapedImageView];
}

- (BOOL)imageLongPressAction:(UIGestureRecognizer *)gestureRecognizer {
    // Check the image property
    UIImageView *longPressedImageView = (UIImageView *)gestureRecognizer.view;
    //
    NSInteger offset = longPressedImageView.tag-EditViewToolNum;
    if([self->imageArray[offset][@"owner"] isEqualToString: @"MyCodesee"]) {
        //
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Alert",nil)
                                                                       message: NSLocalizedString(@"Removethispicture",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* actionOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //                                                             //
                                                             NSString *removeImageFilename = [self->imageArray[offset][@"file"] lastPathComponent];
                                                             //
                                                             NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventEditUpdate], @"remove_img":removeImageFilename};
                                                             [self.viewController processCompleted: param];
                                                         }];
        UIAlertAction* actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 // do nothing
                                                             }];
        [alert addAction: actionOK];
        [alert addAction: actionCancel];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Alert",nil)
                                                                       message: NSLocalizedString(@"Cantbedeletedreadonlypicture",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* actionOK = [UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler: nil];
        [alert addAction: actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    }
    return YES;
}

- (void)imagePickerTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.maximumNumberOfSelection = 6;
    imagePickerController.showsNumberOfSelectedAssets = YES;

    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    NSMutableArray *importedImageArray = [NSMutableArray new];
    //
    self->now = [NSDate date];
    for (PHAsset *asset in assets) {
        // Import those images in Codesee
        PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
        imageRequestOptions.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:imageRequestOptions
                                                    resultHandler:^(NSData *data, NSString *dataUTI, UIImageOrientation orientation,
                                                                    NSDictionary *info)
         {
             //NSLog(@"info = %@", info);
             if ([info objectForKey:@"PHImageFileURLKey"]) {
                 CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                 CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                                        (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                        (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                        (id) kCGImageSourceThumbnailMaxPixelSize : @800
                                                                        };

                 CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
                 UIImage *image = [UIImage imageWithCGImage:scaledImageRef];
                 CGImageRelease(scaledImageRef);
                 // Save image as a jpg file
                 NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                 [dateFormat setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
                 NSString *filename = [NSString stringWithFormat: @"%@.jpg", [dateFormat stringFromDate: self->now]];
                 self->now = [self->now dateByAddingTimeInterval: 1];
                 NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"] , self->qrcode];
                 NSString *file = [qrcodeFolder stringByAppendingPathComponent: filename];
                 NSData *jpg = UIImageJPEGRepresentation(image, 1.0);
                 if([jpg writeToFile: file atomically:YES] == NO) {
                     NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                 }
                 [importedImageArray addObject: filename];
             }
         }];
    }
    //
    NSLog(@"imported images:%@", importedImageArray);
    NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventEditUpdate], @"add_img": [importedImageArray copy]};
    [self.viewController processCompleted: param];
    //
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    //
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)cameraTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    self->imagePicker = [UIImagePickerController new];
    self->imagePicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self->imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        NSLog(@"[Codesee] %s %d not support", __FUNCTION__, __LINE__);
    }

    [self presentViewController:self->imagePicker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Get raw image data
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    // Save image as a jpg file
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *filename = [NSString stringWithFormat: @"%@.jpg", [dateFormat stringFromDate: [NSDate date]]];
    NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"] , self->qrcode];
    NSString *file = [qrcodeFolder stringByAppendingPathComponent: filename];
    NSData *jpg = UIImageJPEGRepresentation(image, 1.0);
    if([jpg writeToFile: file atomically:YES] == NO) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    //
    NSMutableArray *importedImageArray = [NSMutableArray new];
    [importedImageArray addObject: filename];
    NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventEditUpdate], @"add_img": [importedImageArray copy]};
    //
    [self.viewController processCompleted: param];
    [picker dismissViewControllerAnimated:YES completion: nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)noteTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    // Popup dialog in edit view for the descrption of the new QR code
    NSString *note = [self.viewController.qrcodeMetadata getData: @"note"];
    if(note == nil) {
        popup.message = @"";
    } else {
        popup.message = note;
    }
    [popup showPopup];
}

- (void)otherButtonAction:(CustomPopup *)popupView button:(UIButton *)button {
    NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventEditUpdate], @"add_note": popup.message};
    [self.viewController processCompleted: param];
    [popup hidePopup];
}

- (void)cancelButtonAction:(CustomPopup *)popupView button:(UIButton *)button {
    [popup hidePopup];
}

- (void) showPicture: (UIImageView *) imageView {
    NSMutableArray *imageBrowserModels = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self->imageArray.count; i ++) {
        SRPictureModel *imageBrowserModel = [SRPictureModel sr_pictureModelWithPicURLString:self->imageArray[i][@"file"]
                                                                              containerView:imageView.superview
                                                                        positionInContainer:[self->imageViewFrames[i] CGRectValue]
                                                                                      index:i];
        [imageBrowserModels addObject:imageBrowserModel];
    }
    [SRPictureBrowser sr_showPictureBrowserWithModels:imageBrowserModels currentIndex:(imageView.tag-EditViewToolNum) delegate:self];
}

- (NSArray *) listFolderAtPath: (NSString *) path
{
    NSError *error;
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error: &error];
    return dirs;
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
