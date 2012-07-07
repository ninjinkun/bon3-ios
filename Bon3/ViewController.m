//
//  ViewController.m
//  Bon3
//
//  Created by Asano Satoshi on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "OssanView.h"
#define imgExt @"png"
#define imageToData(x) UIImagePNGRepresentation(x)

#define BUFFER_SIZE 16384
#define BUFFER_COUNT 3
#define SAMPLERATE 44100.0f
#define ORIGINAL_SAMPLERATE 8000.0f
#define FL ((2.0f * 3.14159f) / SAMPLERATE) 
#define FR ((2.0f * 3.14159f) / SAMPLERATE) 
#define FRAMECOUNT (1024)
#define NUM_BUFFERS 3

@interface ViewController ()

@end

@implementation ViewController {
    UIWebView *_hiddenWebView;
    AudioQueueRef audioQueue;
    OssanView *_ossanView;
}
@synthesize scrollView = _scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hiddenWebView = [[UIWebView alloc] init];
    _ossanView = [[OssanView alloc] initWithFrame:self.view.bounds];
    [self.scrollView addSubview:_ossanView];
    [self loadHtmlFile:@"index"];    
}

-(void)loadHtmlFile:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"];
    [_hiddenWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

-(NSArray *)loadSamples {
    NSString *js = [NSString stringWithFormat:@"document.get_samples(%d)", FRAMECOUNT];
    NSString *json = [_hiddenWebView stringByEvaluatingJavaScriptFromString:js];
    NSArray *bytes = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    return bytes;
}

-(void)ossanJamp:(float)height {
    height = height > 20 ? height : 0;
    CGRect frame = _ossanView.frame;
    frame.origin.y = -height;
    _ossanView.frame = frame;
    if (height == 0) {
        [_ossanView landing];
    }
    else {
        [_ossanView changeImage];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)chooseMusicButtonPushed:(id)sender {    
    MPMediaPickerController *pickerController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:NO completion:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setupAudioQueue];
    });
}

static void aqCallBack(void *in, AudioQueueRef q, AudioQueueBufferRef qb) { 
    ViewController *self = (__bridge ViewController *)in;
	static int phaseL = 0; 
	static int phaseR = 0; 
	
	short *sinBuffer = (short *)qb->mAudioData; 
	
    float sampleL = 0.0f; 
    float sampleR = 0.0f; 
		
	qb->mAudioDataByteSize = 4 * FRAMECOUNT; 
	// 1 frame per packet, two shorts per frame = 4 * frames 
    NSArray *samples = [self loadSamples];
    // NSLog(@"%@", [samples objectAtIndex:0]);
	for(int i = 0; i < ( FRAMECOUNT * 2 ) ; i+=2) {
        NSNumber *sample = [samples objectAtIndex:i / 2];
        float value = [sample intValue]; //[sample isKindOfClass:[NSNumber class]] ? [sample intValue] : 0;
		sampleL = value / 256.0;//(amplitude * sin(pitch * FL * (float)phaseL));
		sampleR = value / 256.0;//(amplitude * sin(pitch * FR * (float)phaseR));
        
		short sampleIL = (int)(sampleL * 32767.0f); 
		short sampleIR = (int)(sampleR * 32767.0f); 
		sinBuffer[i] = sampleIL; 
		sinBuffer[i+1] = sampleIR; 
		phaseL++; 
		phaseR++; 
	} 
    OSStatus error = AudioQueueEnqueueBuffer(q, qb, 0, NULL);
    
    DSPSplitComplex splitComplex;
    splitComplex.realp = calloc(FRAMECOUNT, sizeof(float));
    splitComplex.imagp = calloc(FRAMECOUNT, sizeof(float));
    for (int i = 0; i < FRAMECOUNT; i++) {
        splitComplex.realp[i] = sinBuffer[i];
    }
    FFTSetup fftSetup = vDSP_create_fftsetup(9, FFT_RADIX2);
    vDSP_fft_zrip(fftSetup, &splitComplex, 1, 9, FFT_FORWARD);
    vDSP_destroy_fftsetup(fftSetup);
    free(splitComplex.realp);
    free(splitComplex.imagp);
    int spectrum[4];
    for (int i=0; i< FRAMECOUNT / 2; i++) {// 半分よりあっち側は無意味なので無視するよ!
        float real = splitComplex.realp[i];
        float imag = splitComplex.imagp[i];
        float distance = sqrt(real*real + imag*imag);
        spectrum[i / (FRAMECOUNT / 2 / 4)] += distance;
    }
    [self ossanJamp:spectrum[1] / 80000];
} 

-(void)setupAudioQueue {
    OSStatus err = noErr;
    // Setup the audio device.
    AudioStreamBasicDescription deviceFormat;
    deviceFormat.mSampleRate = SAMPLERATE;
    deviceFormat.mFormatID = kAudioFormatLinearPCM;
    deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    deviceFormat.mBytesPerPacket = 4;
    deviceFormat.mFramesPerPacket = 1;
    deviceFormat.mBytesPerFrame = 4;
    deviceFormat.mChannelsPerFrame = 2;
    deviceFormat.mBitsPerChannel = 8;
    // Create a new output AudioQueue for the device.
    err = AudioQueueNewOutput(&deviceFormat, aqCallBack, (__bridge void *)self,
                              CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
                              0, &audioQueue);
    // Allocate buffers for the AudioQueue, and pre-fill them.

    for (int i = 0; i < NUM_BUFFERS; ++i) {
        AudioQueueBufferRef mBuffer;
        err = AudioQueueAllocateBuffer(audioQueue, FRAMECOUNT * deviceFormat.mBytesPerFrame, &mBuffer);
        if (err != noErr) break;
        aqCallBack((__bridge void *)self, audioQueue, mBuffer);
    }
    if (err == noErr) err = AudioQueueStart(audioQueue, NULL);
    if (err == noErr) CFRunLoopRun();
}

@end
