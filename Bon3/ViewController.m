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

#define BUFFER_SIZE 16384
#define BUFFER_COUNT 3
#define MUSIC_LENGTH_SECONDS (10)
#define SAMPLERATE 44100.0f
#define ORIGINAL_SAMPLERATE 8000.0f
#define FL ((2.0f * 3.14159f) / SAMPLERATE) 
#define FR ((2.0f * 3.14159f) / SAMPLERATE) 
#define FRAMECOUNT (1024)
#define PRELOADING_FRAMECOUNT (MUSIC_LENGTH_SECONDS * SAMPLERATE)
#define NUM_BUFFERS 3

@interface ViewController ()
@property (nonatomic) short *playingSamples;
@property (nonatomic) short *loadedSamples;
@property (nonatomic) NSInteger curretnPlayingIndex;
@end

@implementation ViewController {
    UIWebView *_hiddenWebView;
    AudioQueueRef audioQueue;
    OssanView *_ossanView;
}
@synthesize scrollView = _scrollView;
@synthesize loadedSamples = _loadedSamples;
@synthesize playingSamples = _playingSamples;
@synthesize curretnPlayingIndex = _curretnPlayingIndex;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpViews];
    [self loadHtmlFile:@"index"];    
}

-(void)setUpViews {
    _hiddenWebView = [[UIWebView alloc] init];
    _ossanView = [[OssanView alloc] initWithFrame:self.view.bounds];
    [self.scrollView addSubview:_ossanView];    
}

-(void)loadHtmlFile:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"];
    [_hiddenWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

-(void)loadSamples {
    NSArray *samples = [self getSamplesWithJS];
    free(_loadedSamples);
    _loadedSamples = calloc(PRELOADING_FRAMECOUNT, sizeof(short));
    int i = 0;    
    for (NSNumber *number in samples) {        
        _loadedSamples[i++] = [number shortValue];
    }
}

-(NSArray *)getSamplesWithJS {
    NSString *js = [NSString stringWithFormat:@"document.get_samples(%d)", (NSInteger)PRELOADING_FRAMECOUNT];    
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.curretnPlayingIndex = 0;
        [self loadSamples];
        self.playingSamples = self.loadedSamples;        
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
    short fftBuf[FRAMECOUNT];
	for(int i = 0; i < ( FRAMECOUNT * 2 ) ; i+=2) {        
        float value = fabs(self.playingSamples[i/2 + self.curretnPlayingIndex]);
		sampleL = value / 256.0;//(amplitude * sin(pitch * FL * (float)phaseL));
		sampleR = value / 256.0;//(amplitude * sin(pitch * FR * (float)phaseR));
		short sampleIL = (int)(sampleL * 32767.0f); 
		short sampleIR = (int)(sampleR * 32767.0f); 
		sinBuffer[i] = sampleIL; 
		sinBuffer[i+1] = sampleIR; 
        fftBuf[i/2] = sampleIL;
		phaseL++; 
		phaseR++; 
	} 
    self.curretnPlayingIndex += FRAMECOUNT;
    AudioQueueEnqueueBuffer(q, qb, 0, NULL);    
    
    DSPSplitComplex splitComplex;
    splitComplex.realp = calloc(FRAMECOUNT, sizeof(float));
    splitComplex.imagp = calloc(FRAMECOUNT, sizeof(float));
    for (int i = 0; i < FRAMECOUNT; i++) {
        splitComplex.realp[i] = fftBuf[i];
    }
    FFTSetup fftSetup = vDSP_create_fftsetup(9, FFT_RADIX2);
    vDSP_fft_zrip(fftSetup, &splitComplex, 1, 9, FFT_FORWARD);
    vDSP_destroy_fftsetup(fftSetup);    
    int spectrum[4] = {0, 0, 0, 0};
    
    for (int i=0; i< FRAMECOUNT / 2; i++) {
        float real = splitComplex.realp[i];
        float imag = splitComplex.imagp[i];
        float distance = sqrt(real*real + imag*imag);
        int index = i / (FRAMECOUNT / 2 / 4);
        spectrum[index] += distance;
    }    

    [self ossanJamp:spectrum[1] / 80000];            

    
    free(splitComplex.realp);
    free(splitComplex.imagp);
    if (self.curretnPlayingIndex >= PRELOADING_FRAMECOUNT) {
        self.playingSamples = self.loadedSamples;  // 曲が入れ替わる
        self.curretnPlayingIndex = 0;
        [self loadSamples]; // 次の曲の準備
    }    
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
