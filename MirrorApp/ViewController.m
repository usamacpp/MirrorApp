//
//  ViewController.m
//  MirrorApp
//
//  Created by osama mourad on 12/22/14.
//  Copyright (c) 2014 osama mourad. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _captureImage.hidden = YES;
    _btn_close.hidden = YES;
    //_imagePreview.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [self adjustToolbar];
    
    _captureImage.hidden = YES;
    _btn_close.hidden = YES;
    
    if(![self setupAVCapture])
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to acquire front camera device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)adjustToolbar {
    //UIScreen *scr = [UIScreen mainScreen];
    //_toolbar.bounds = CGRectMake(0, scr.bounds.size.height, scr.bounds.size.width, _toolbar.frame.size.height);
    
    UIBarButtonItem *spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCamera target:self action:@selector(saveCapturedImage)];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingss.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settings)];
    
    NSArray *items = [[NSArray alloc] initWithObjects: shareButton, spacerItem, saveButton, spacerItem, settingsButton, nil];
    
    [self.toolbar setItems: items];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - toolbar items

-(void)shareAction {
    NSLog(@"Share Action");
    
    [self shareImage];
}

-(void)saveCapturedImage {
    NSLog(@"Save image to lib");
    
    [self saveImage];
    
}

-(void)settings {
    NSLog(@"Settings");
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Not implemented yet!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - AV session

- (BOOL)setupAVCapture
{
    @try {
        NSError *error = nil;
        
        AVCaptureSession *session = [AVCaptureSession new];
        [session setSessionPreset:AVCaptureSessionPresetHigh];
        
        // Select a video device, make an input
        AVCaptureDevice *fCamera = nil;
        NSArray *devices = [AVCaptureDevice devices];
        
        for (AVCaptureDevice *device in devices) {
            
            NSLog(@"Device name: %@", [device localizedName]);
            
            if ([device hasMediaType:AVMediaTypeVideo]) {
                
                if ([device position] == AVCaptureDevicePositionFront) {
                    fCamera = device;
                    break;
                }
            }
        }
        
        if (fCamera == nil)
            return NO;
        
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:fCamera error:&error];
        if (error)
            return NO;
        if ([session canAddInput:input])
            [session addInput:input];
        
        //Make video output
        _videoOutput = [AVCaptureVideoDataOutput new];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
        [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        [_videoOutput setSampleBufferDelegate:self queue: dispatch_get_main_queue()];
        if ([session canAddOutput:_videoOutput])
            [session addOutput:_videoOutput];
        
        // Make a preview layer so we can see the visual output of an AVCaptureSession
        AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        previewLayer.frame = _imagePreview.frame = [UIScreen mainScreen].bounds;
        
        // add the preview layer to the hierarchy
        CALayer *rootLayer = [_imagePreview layer];
        [rootLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [rootLayer addSublayer:previewLayer];
        
        // start the capture session running, note this is an async operation
        // status is provided via notifications such as AVCaptureSessionDidStartRunningNotification/AVCaptureSessionDidStopRunningNotification
        [session startRunning];
        
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to setup");
    }
    
    return NO;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(_captureImage.hidden == NO) {
        
        if(_captureImage.image == nil) {
            CGImageRef cgImage = [ViewController imageFromSampleBuffer:sampleBuffer];
            capturedImageData = UIImagePNGRepresentation([UIImage imageWithCGImage:cgImage]);
            
            //_imagePreview.hidden = YES;
            [self processImage: [UIImage imageWithData: capturedImageData]];
            
            CGImageRelease(cgImage);
        }
    }
    else
        _lastFrame = sampleBuffer;
}

+ (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    return newImage;
}

- (IBAction)cameraTabbed:(UITapGestureRecognizer *)sender {
    NSLog(@"camera preview tabbed");
    
    _captureImage.image = nil; //remove old image from view
    _captureImage.hidden = NO; //show the captured image view
    _btn_close.hidden = NO;
    //capturedImageData = nil;
    //[self capImage];
    
    [self animate];
}

- (IBAction)stillImageTabbed:(UITapGestureRecognizer *)sender {
    NSLog(@"captured image tabbed");
    
    [self freeze];
}

- (IBAction)btn_close_press:(UIButton *)sender {
    NSLog(@"close button pressed");
    
    [self freeze];
}

-(void)freeze {
    _imagePreview.hidden = NO;
    _captureImage.hidden = YES;
    _btn_close.hidden = YES;
    
    capturedImageData = nil;
    
    [self animate];
}

-(void) processImage:(UIImage*) image {
    //mirroring the captured image
    UIImage *mirroredImage = [UIImage imageWithCGImage: image.CGImage scale: 1.0f orientation: UIImageOrientationLeftMirrored];
    
    [_captureImage setImage: mirroredImage];
}

-(void) saveImage{
    if (_captureImage.image != nil) {
        UIImageWriteToSavedPhotosAlbum(_captureImage.image, nil, nil, nil);
    }
    else
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No Active photo taken to save" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

-(void)animate
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect = _toolbar.frame;
    UIScreen *scr = [UIScreen mainScreen];
    
    if(_captureImage.hidden == NO)
    {
        rect.origin.y = scr.bounds.size.height - _toolbar.frame.size.height;
        _toolbar.frame=rect;
    }
    else
    {
        rect.origin.y = scr.bounds.size.height;
        _toolbar.frame=rect;
    }
    
    [UIView commitAnimations];
}

-(void)shareImage
{
    if (_captureImage.image != nil) {
        NSMutableArray *sharingItems = [NSMutableArray new];
        
        if (_captureImage.image) {
            [sharingItems addObject:_captureImage.image];
        }
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:^{
            
            if(_captureImage.hidden == YES)
                _btn_close.hidden = YES;
            else
                _btn_close.hidden = NO;
        }];
    }
    else
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"No Active photo taken to share" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

@end
