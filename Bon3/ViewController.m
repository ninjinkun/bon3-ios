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
#import <QuartzCore/QuartzCore.h>
#import "OssansBaseView.h"
#import "InfoViewController.h"
#import "MixpanelAPI.h"
#import <Twitter/Twitter.h>

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
    AudioQueueRef _audioQueue;    
    IBOutlet UIButton *_tweetButton;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    InfoViewController *viewController = (InfoViewController *)segue.destinationViewController;
    viewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    viewController.screenImage = [self captureScreen];
}

-(UIImage *)captureScreen {
 	UIImage *capture;
    NSLog(@"frame %@", NSStringFromCGSize(self.view.bounds.size));
	UIGraphicsBeginImageContext(self.view.bounds.size);
	[self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
	capture = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return capture;   
}

-(IBAction)twitterButtonPushed:(id)sender {
    [[MixpanelAPI sharedAPI] track:@"Tweet Button Tapped"];
    _tweetButton.hidden = YES;
    TWTweetComposeViewController *twitterViewController = [[TWTweetComposeViewController alloc] init];
    
    [twitterViewController addImage:[self captureScreen]];
    [twitterViewController setInitialText:NSLocalizedString(@"Dancing with #bon3", @"Twieet Text")];
    [twitterViewController addURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/bon3/"]];
    [twitterViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result){
        if (result == TWTweetComposeViewControllerResultDone)
            [[MixpanelAPI sharedAPI] track:@"Tweeted"];
        else
            [[MixpanelAPI sharedAPI] track:@"Tweet Canceled"];
        
        _tweetButton.hidden = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:twitterViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpViews];
    [self loadHtmlFile:@"index"];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.curretnPlayingIndex = 0;
        [self loadSamples];
        self.playingSamples = self.loadedSamples;        
        [self setupAudioQueue];
    });
}

-(CGFloat)groundHeight {
    return floor(self.view.frame.size.height / 480 * 40);
}

-(void)setUpViews {
    _hiddenWebView = [[UIWebView alloc] init];
    
    _groundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [self groundHeight], self.view.bounds.size.width, [self groundHeight])];
    _groundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view insertSubview:_groundView atIndex:0];

    _ossanView = [[OssansBaseView alloc] initWithFrame:CGRectMake(0, -[self groundHeight], self.view.frame.size.width, self.view.frame.size.height)];    
    _ossanView.ossansCount = 1;
    _groundView.backgroundColor = _ossanView.ossanColor = [UIColor colorWithRed: 1.0 green: 0.3671875 blue: 0.58984375 alpha: 1.0];
    {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ossanTapped:)];
        [_ossanView addGestureRecognizer:recognizer];
    }
    {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ossanTapped:)];
        [_groundView addGestureRecognizer:recognizer];             
    }
    [self.view insertSubview:_ossanView atIndex:0];
}

-(void)ossanTapped:(UITapGestureRecognizer *)sender {
    [[MixpanelAPI sharedAPI] track:@"Ossan Tapped"];
    _groundView.backgroundColor = _ossanView.ossanColor = [UIColor colorWithHue: (float)(arc4random()%360) / 360.0 saturation:1.0 brightness:1.0 alpha:1.0];
    [self nextTrack];
    [self loadSamples];
}

-(void)loadHtmlFile:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"];
    [_hiddenWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

-(void)nextTrack {
     NSString *js = @"document.reset()";
    [_hiddenWebView stringByEvaluatingJavaScriptFromString:js];
}

-(void)loadSamples {
    _loadedSamples = [self getSamplesWithJS];
}

-(NSString *)getSamplesWithJS {
//    NSDate *start = [NSDate date];
    NSString *js = [NSString stringWithFormat:@"document.get_samples(%d)", (NSInteger)PRELOADING_FRAMECOUNT];

    NSString *json = [_hiddenWebView stringByEvaluatingJavaScriptFromString:js];
//    NSLog(@"web view %f", [[NSDate date] timeIntervalSinceDate:start]);

    return json;
}

-(void)ossanJamp:(NSArray *)ossanValues {
    _ossanView.ossanHeights = ossanValues;
    CGRect frame =  _ossanView.frame;    

    float groundHeight = [self groundHeight];
    for (NSNumber *num in ossanValues) {
        groundHeight += [num floatValue];
    }
    // てきとう
    groundHeight /= 1000000;
    groundHeight *= self.view.frame.size.height / 160;
    groundHeight = groundHeight > self.view.frame.size.height / 16 + [self groundHeight] ? groundHeight : [self groundHeight];
    frame.origin.y = -groundHeight;
    _ossanView.frame = frame;
    frame = _groundView.frame;
    frame.size.height = groundHeight;
    frame.origin.y = self.view.bounds.size.height - groundHeight;
    _groundView.frame = frame;
}

- (void)viewDidUnload
{
    _tweetButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{    
    return YES;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [[MixpanelAPI sharedAPI] track:UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? @"Rotate to Portrait" : @"Rotate to Landscape"];
    _ossanView.ossansCount = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? 1 : 4;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _ossanView.ossansCount = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 1 : 4;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[MixpanelAPI sharedAPI] track:@"Ossan Page Shown"];
    // リモコンを操作できないように
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
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
            [ossanValues addObject:@(spectrum[i])];
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
                              0, &_audioQueue);
    // Allocate buffers for the AudioQueue, and pre-fill them.

    for (int i = 0; i < NUM_BUFFERS; ++i) {
        AudioQueueBufferRef mBuffer;
        err = AudioQueueAllocateBuffer(_audioQueue, FRAMECOUNT * deviceFormat.mBytesPerFrame, &mBuffer);
        if (err != noErr) break;
        aqCallBack((__bridge void *)self, _audioQueue, mBuffer);
    }
    if (err == noErr) err = AudioQueueStart(_audioQueue, NULL);
}

-(void)stopAudioQueue {
    AudioQueueStop(_audioQueue, YES);
}

@end
