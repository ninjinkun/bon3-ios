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
#define imgExt @"png"
#define imageToData(x) UIImagePNGRepresentation(x)
@interface ViewController ()

@end

@implementation ViewController
@synthesize contentView = _contentView;
@synthesize scrollView = _scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadResource:@"image4"];
}

- (void)loadResource:(NSString *)name
{
    [self.contentView removeFromSuperview];
    
	SVGDocument *document = [SVGDocument documentNamed:[name stringByAppendingPathExtension:@"svg"]];
	NSLog(@"[%@] Freshly loaded document (name = %@) has width,height = (%.2f, %.2f)", [self class], name, document.width, document.height );
	self.contentView = [[SVGView alloc] initWithDocument:document];

    [self.scrollView addSubview:self.contentView];
    [self.scrollView setContentSize:CGSizeMake(document.width * 2, document.height * 2)];
    [self.scrollView zoomToRect:CGRectMake(0, 0, document.width, document.height) animated:YES];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(void)chooseMusicButtonPushed:(id)sender {
    
    MPMediaPickerController *pickerController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:NO completion:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    SetupAudioQueue();
}

#define BUFFER_SIZE 16384
#define BUFFER_COUNT 3
static AudioQueueRef audioQueue;
#define SAMPLERATE 44100.0f
#define FL ((2.0f * 3.14159f) / SAMPLERATE) 
#define FR ((2.0f * 3.14159f) / SAMPLERATE) 
#define FRAMECOUNT (1024)
#define NUM_BUFFERS 3

static void aqCallBack(void *in, AudioQueueRef q, AudioQueueBufferRef qb) { 
	static int phaseL = 0; 
	static int phaseR = 0; 
	
	short *sinBuffer = (short *)qb->mAudioData; 
	
    int sampleL = 0.0f; 
    int sampleR = 0.0f; 
	
	float amplitude = 1.0f, pitch=100.0f;
	
	qb->mAudioDataByteSize = 4 * FRAMECOUNT; 
	// 1 frame per packet, two shorts per frame = 4 * frames 
	for(int i = 0; i < ( FRAMECOUNT * 2 ) ; i+=2) {
//		sampleL = (amplitude * sin(pitch * FL * (float)phaseL));
        sampleR = sampleL = sin(i/10) * 80 + 120;
//		sampleR = (amplitude * sin(pitch * FR * (float)phaseR));
        
		short sampleIL = sampleL % 256;//(int)(sampleL * 32767.0f); 
		short sampleIR = sampleR % 256;//(int)(sampleR * 32767.0f); 
		sinBuffer[i] = sampleIL; 
		sinBuffer[i+1] = sampleIR; 
		phaseL++; 
		phaseR++; 
	}//end for
	AudioQueueEnqueueBuffer(q, qb, 0, NULL); 
} 

void SetupAudioQueue() {
    OSStatus err = noErr;
    // Setup the audio device.
    AudioStreamBasicDescription deviceFormat;
    deviceFormat.mSampleRate = 8000;
    deviceFormat.mFormatID = kAudioFormatLinearPCM;
    deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    deviceFormat.mBytesPerPacket = 4;
    deviceFormat.mFramesPerPacket = 1;
    deviceFormat.mBytesPerFrame = 4;
    deviceFormat.mChannelsPerFrame = 2;
    deviceFormat.mBitsPerChannel = 8;
    deviceFormat.mReserved = 0;
    // Create a new output AudioQueue for the device.
    err = AudioQueueNewOutput(&deviceFormat, aqCallBack, NULL,
                              CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
                              0, &audioQueue);
    // Allocate buffers for the AudioQueue, and pre-fill them.
    for (int i = 0; i < NUM_BUFFERS; ++i) {
        AudioQueueBufferRef mBuffer;
        err = AudioQueueAllocateBuffer(audioQueue, FRAMECOUNT * deviceFormat.mBytesPerFrame, &mBuffer);
        if (err != noErr) break;
        aqCallBack(NULL, audioQueue, mBuffer);
    }
    if (err == noErr) err = AudioQueueStart(audioQueue, NULL);
    if (err == noErr) CFRunLoopRun();
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    MPMediaItem *item = [mediaItemCollection.items lastObject];
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];

}

- (NSData *) renderPNGAudioPictogramForAssett:(AVURLAsset *)songAsset {
    
    NSError * error = nil;
    
    
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    AVAssetTrack * songTrack = [songAsset.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
                                        
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            //    NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 normalizeMax = 0;
    
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    
    UInt64 totalBytes = 0; 
    
    
    SInt64 totalLeft = 0;
    SInt64 totalRight = 0;
    NSInteger sampleTally = 0;
    
    NSInteger samplesPerPixel = sampleRate / 50;
    
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
                        
            @autoreleasepool {            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = length / bytesPerSample;
            for (int i = 0; i < sampleCount ; i ++) {
                
                SInt16 left = *samples++;
                
                totalLeft  += left;
                
                
                
                SInt16 right;
                if (channelCount==2) {
                    right = *samples++;
                    
                    totalRight += right;
                }
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel) {
                    
                    left  = totalLeft / sampleTally; 
                    
                    SInt16 fix = abs(left);
                    if (fix > normalizeMax) {
                        normalizeMax = fix;
                    }
                    
                    
                    [fullSongData appendBytes:&left length:sizeof(left)];
                    
                    if (channelCount==2) {
                        right = totalRight / sampleTally; 
                        
                        
                        SInt16 fix = abs(right);
                        if (fix > normalizeMax) {
                            normalizeMax = fix;
                        }
                        
                        
                        [fullSongData appendBytes:&right length:sizeof(right)];
                    }
                    
                    totalLeft   = 0;
                    totalRight  = 0;
                    sampleTally = 0;
                    
                }
            }
            
            
            }

            
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    
    NSData * finalData = nil;
    
    if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        // Something went wrong. return nil
        
        return nil;
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        NSLog(@"rendering output graphics using normalizeMax %d",normalizeMax);
        
        UIImage *test = [self audioImageGraph:(SInt16 *) 
                         fullSongData.bytes 
                                 normalizeMax:normalizeMax 
                                  sampleCount:fullSongData.length / 4 
                                 channelCount:2
                                  imageHeight:100];
        
        finalData = imageToData(test);
    }
    
    return finalData;
}

-(UIImage *) audioImageGraph:(SInt16 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount 
                channelCount:(NSInteger) channelCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[UIColor whiteColor] CGColor];
    CGColorRef rightcolor = [[UIColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight;
    float centerRight = (halfGraphHeight*3) ; 
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt16 left = *samples++;
        float pixels = (float) left;
        pixels *= sampleAdjustmentFactor;
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
        if (channelCount==2) {
            SInt16 right = *samples++;
            float pixels = (float) right;
            pixels *= sampleAdjustmentFactor;
            CGContextMoveToPoint(context, intSample, centerRight - pixels);
            CGContextAddLineToPoint(context, intSample, centerRight + pixels);
            CGContextSetStrokeColorWithColor(context, rightcolor);
            CGContextStrokePath(context); 
        }
    }
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();   
    
    return newImage;
}

@end
