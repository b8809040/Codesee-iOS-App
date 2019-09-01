//
//  ScanViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/18.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "ScanViewController.h"
#import <CodeseeSDK/CodeseeSDK.h>
#import "CodeseeStatus.h"

@interface ScanViewController ()
{
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    AVCaptureVideoDataOutput *captureVideoDataOutput;
    AVMetadataMachineReadableCodeObject *metadataMachineReadableCodeObject;
    CodeseeAuth *auth;
    UIImage *qrcodeImage;
}
@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self->auth = [CodeseeAuth new];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if([self->captureSession isRunning] == NO) {
        [self startScanning];
    } else {
        [self->captureSession startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    // TODO: should be tested more
    if([self->captureSession isRunning] == YES) {
        [self->captureSession stopRunning];
    }
}

- (BOOL)startScanning
{
    self->metadataMachineReadableCodeObject = nil;
    self->qrcodeImage = nil;
    NSError *error;
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!captureDeviceInput) {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"[Codesee] error:%@", [error localizedDescription]);
        return NO;
    }
    // Initialize the captureSession object.
    self->captureSession = [AVCaptureSession new];
    // Begin capture session configuration
    [self->captureSession beginConfiguration];
    // Add the capture input device to the session
    if ([self->captureSession canAddInput: captureDeviceInput]) {
        [self->captureSession addInput: captureDeviceInput];
    }
    // Create capture metadata output for QR code scanning
    AVCaptureMetadataOutput *captureMetadataOutput = [AVCaptureMetadataOutput new];
    if ([self->captureSession canAddOutput:captureMetadataOutput]) {
        [self->captureSession addOutput:captureMetadataOutput];
        //
        dispatch_queue_t metadataOutputQueue = dispatch_queue_create("metadata-output-queue", DISPATCH_QUEUE_SERIAL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue: metadataOutputQueue];
        [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    }
    // Create capture video data output for frame image
    self->captureVideoDataOutput = [AVCaptureVideoDataOutput new];
    if ([self->captureSession canAddOutput: self->captureVideoDataOutput]) {
        [self->captureSession addOutput: self->captureVideoDataOutput];
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [self->captureVideoDataOutput setVideoSettings:rgbOutputSettings];
        [self->captureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [[self->captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("video-data-output-queue", DISPATCH_QUEUE_SERIAL);
        [self->captureVideoDataOutput setSampleBufferDelegate:self queue: videoDataOutputQueue];
    }
    // Finish capture session configuration
    [self->captureSession commitConfiguration];
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    self->captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: self->captureSession];
    [self->captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self->captureVideoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer: self->captureVideoPreviewLayer];
    // Add focus icon on the middle of previewing screen
    UIImageView *focusIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"focus-frame.png"]];
    [focusIcon setAlpha:0.88];
    [self.view addSubview:focusIcon];
    [focusIcon setTranslatesAutoresizingMaskIntoConstraints:NO];
    // Add constraint to the icon
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:focusIcon attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0f constant:-0.0f];
    [self.view addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:focusIcon attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0f constant:-0.0f];
    [self.view addConstraint:constraint];
    // Start video capture.
    [self->captureSession startRunning];

    return YES;
}

-(void)stopScanning: (NSString *) encryptedQRCode
{
    // Stop video capture and make the capture session object nil.
    [self->captureSession stopRunning];
    self->captureSession = nil;
    // Remove the video preview layer from the viewPreview view's layer.
    [self->captureVideoPreviewLayer removeFromSuperlayer];
    // Verify the encrypted QR code
    NSString *qrcode = [self->auth authenticate: encryptedQRCode];
    if(qrcode == nil) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert",nil)
                                                                       message:NSLocalizedString(@"IncorrectQRcodeformat",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* actionOK = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             // Pass parameter to main tab view
                                                             NSDictionary *param = @{@"event":[NSNumber numberWithInt: CodeseeEventScanRetry]};
                                                             [self.viewController processCompleted: param];
                                                         }];
        [alert addAction: actionOK];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // Sanitize QR code
        qrcode = [qrcode stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        // Pass parameter to main tab view
        NSDictionary *param = @{@"qrcode":qrcode, @"qrcode_image":qrcodeImage};
        [self.viewController processCompleted: param];
    }
 }

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // イメージバッファの取得
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    // イメージバッファ情報の取得
    uint8_t *base = CVPixelBufferGetBaseAddress(buffer);
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,
                                                   kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // 画像の作成
    CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
    UIImage* image = [UIImage imageWithCGImage:cgImage scale:1.0f
                                   orientation:UIImageOrientationRight]; // 90度右に回転
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}

// Public functions

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self->metadataMachineReadableCodeObject == nil || self->qrcodeImage != nil) return;
    // Covert CMSampleBufferRef to UIImage
    self->qrcodeImage = [self imageFromSampleBuffer: sampleBuffer];
    // Add your code here that uses the image.
    [self performSelectorOnMainThread:@selector(stopScanning:) withObject: self->metadataMachineReadableCodeObject.stringValue waitUntilDone:NO];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0 && self->metadataMachineReadableCodeObject == nil) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            self->metadataMachineReadableCodeObject = metadataObj;
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            //[self performSelectorOnMainThread:@selector(stopScanning:) withObject:metaData.stringValue waitUntilDone:NO];
        }
    }
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
