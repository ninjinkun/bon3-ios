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
#import "OssansBaseView.h"
#define BUFFER_SIZE 16384
#define BUFFER_COUNT 3
#define MUSIC_LENGTH_SECONDS ()
#define SAMPLERATE 44100.0f
#define ORIGINAL_SAMPLERATE 8000.0f
#define FL ((2.0f * 3.14159f) / SAMPLERATE) 
#define FR ((2.0f * 3.14159f) / SAMPLERATE) 
#define FRAMECOUNT (1024)
#define PRELOADING_FRAMECOUNT (1024)
#define NUM_BUFFERS 3

@interface ViewController ()
@property (nonatomic, strong) NSString *playingSamples;
@property (nonatomic, strong) NSString *loadedSamples;
@property (nonatomic) NSInteger curretnPlayingIndex;
@property (nonatomic, strong) OssansBaseView *ossanView;;
@property (nonatomic, strong) UIView *groundView;
@end

@implementation ViewController {
    UIWebView *_hiddenWebView;
    AudioQueueRef audioQueue;    
}
@synthesize scrollView = _scrollView;
@synthesize loadedSamples = _loadedSamples;
@synthesize playingSamples = _playingSamples;
@synthesize curretnPlayingIndex = _curretnPlayingIndex;
@synthesize ossanView = _ossanView;
@synthesize groundView = _groundView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpViews];
    [self loadHtmlFile:@"index"];    
}

-(void)setUpViews {
    _hiddenWebView = [[UIWebView alloc] init];
    
    _groundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 40, self.view.bounds.size.width, 40)];
    _groundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [_scrollView addSubview:_groundView];

    _ossanView = [[OssansBaseView alloc] initWithFrame:CGRectMake(0, -40, self.view.frame.size.width, self.view.frame.size.height)];    
    _ossanView.ossansCount = 1;
    _groundView.backgroundColor = _ossanView.ossanColor = [UIColor greenColor];
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ossanTapped:)];
    [_scrollView addGestureRecognizer:recognizer];
    [self.scrollView addSubview:_ossanView];    
}

-(void)ossanTapped:(UITapGestureRecognizer *)sender {
    float red = arc4random() % 2;
    float green = arc4random() % 2;
    float blue = arc4random() % 2;
    red = red + green + blue >= 3 ? 0 : red;    
    _groundView.backgroundColor = _ossanView.ossanColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    [self loadSamples];
}

-(void)loadHtmlFile:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"];
    [_hiddenWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

-(void)loadSamples {
    _loadedSamples = [self getSamplesWithJS];
}

-(NSString *)getSamplesWithJS {
    NSDate *start = [NSDate date];
    NSString *js = [NSString stringWithFormat:@"document.get_samples(%d)", (NSInteger)PRELOADING_FRAMECOUNT];

    NSString *json = [_hiddenWebView stringByEvaluatingJavaScriptFromString:js];
//    NSLog(@"web view %f", [[NSDate date] timeIntervalSinceDate:start]);
//    
//    NSArray *bytes = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
//    NSLog(@"json %f", [[NSDate date] timeIntervalSinceDate:start]);

    return json;
}

-(void)ossanJamp:(NSArray *)ossanValues {
    _ossanView.ossanHeights = ossanValues;
    CGRect frame =  _ossanView.frame;    

    float groundHeight = 40.0; 
    for (NSNumber *num in ossanValues) {
        groundHeight += [num floatValue];
    }
    groundHeight /= 1000000;
    groundHeight = groundHeight > 10 + 40 ? groundHeight : 40;
    frame.origin.y = -groundHeight;
    _ossanView.frame = frame;
    frame = _groundView.frame;
    frame.size.height = groundHeight;
    frame.origin.y = self.view.bounds.size.height - groundHeight;
    _groundView.frame = frame;
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

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _ossanView.ossansCount = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 1 : 4;
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
    int playingBuf[FRAMECOUNT];
    NSScanner *scanner = [NSScanner scannerWithString:self.playingSamples];    

    scanner.scanLocation = self.curretnPlayingIndex;
    for (int i = 0; i < FRAMECOUNT; i++) {
        [scanner scanInt:&playingBuf[i]];
    }
	for(int i = 0; i < ( FRAMECOUNT * 2 ) ; i+=2) {
        float value = fabs(playingBuf[i/2]);
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
    
    for (int i = 0; i < FRAMECOUNT / 2; i++) {
        float real = splitComplex.realp[i];
        float imag = splitComplex.imagp[i];
        float distance = sqrt(real*real + imag*imag);
        int index = i / (FRAMECOUNT / 2 /  self.ossanView.ossansCount);
        spectrum[index] += distance;
    }   
    
    {
        NSMutableArray *ossanValues = [NSMutableArray array];
        for (int i = 0; i < self.ossanView.ossansCount; i++) {
            [ossanValues addObject:[NSNumber numberWithInt:spectrum[i]]];
        }        
        [self ossanJamp:ossanValues];
    }
    
    free(splitComplex.realp);
    free(splitComplex.imagp);
    if (self.curretnPlayingIndex >= PRELOADING_FRAMECOUNT) {        
        self.playingSamples = self.loadedSamples;  // 曲が入れ替わる
        self.curretnPlayingIndex = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadSamples]; // 次の曲の準備
        });
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
}

@end
