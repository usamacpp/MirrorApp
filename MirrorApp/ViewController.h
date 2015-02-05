//
//  ViewController.h
//  MirrorApp
//
//  Created by osama mourad on 12/22/14.
//  Copyright (c) 2014 osama mourad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate> {
    NSData *capturedImageData;
}

@property(nonatomic, retain) AVCaptureVideoDataOutput *videoOutput;

@property(nonatomic) CMSampleBufferRef lastFrame;

@property (weak, nonatomic) IBOutlet UIView *imagePreview;
@property (weak, nonatomic) IBOutlet UIImageView *captureImage;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIButton *btn_close;

- (IBAction)cameraTabbed:(UITapGestureRecognizer *)sender;
- (IBAction)stillImageTabbed:(UITapGestureRecognizer *)sender;
- (IBAction)btn_close_press:(UIButton *)sender;

+ (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;

@end

