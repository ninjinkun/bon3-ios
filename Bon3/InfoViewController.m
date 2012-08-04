//
//  InfoViewController.m
//  Bon3
//
//  Created by Asano Satoshi on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"
#import "MixpanelAPI.h"
#import <Twitter/Twitter.h>

@implementation InfoViewController {    
    IBOutlet UIButton *_tweetButton;
    IBOutlet UIButton *_aboutUsButton;
    IBOutlet UILabel *_titleLabel;
}

-(IBAction)twitterButtonPushed:(id)sender {
    [[MixpanelAPI sharedAPI] track:@"Tweet Button Tapped"];    
    TWTweetComposeViewController *twitterViewController = [[TWTweetComposeViewController alloc] init];
    if (_screenImage) 
        [twitterViewController addImage:_screenImage];    
    [twitterViewController setInitialText:NSLocalizedString(@"Dancing with #bon3", @"Twieet Text")];
    [twitterViewController addURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/bon3/"]];
    [twitterViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result){
        if (result == TWTweetComposeViewControllerResultDone)
            [[MixpanelAPI sharedAPI] track:@"Tweeted"];
        else
            [[MixpanelAPI sharedAPI] track:@"Tweet Canceled"];                

        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:twitterViewController animated:YES completion:nil];
}

-(IBAction)aboutUsButtonPushed:(id)sender {
    [[MixpanelAPI sharedAPI] track:@"Aboutn Us Button Tapped"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/"]];
}

-(IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tweetButton.enabled = [TWTweetComposeViewController canSendTweet];
    [self setUpLocalizedText];
}

-(void)setUpLocalizedText {
    _titleLabel.text = NSLocalizedString(@"Dance music goes on", @"Dance music goes on");
    [_tweetButton setTitle:NSLocalizedString(@"Tweet bon3", @"Tweet bon3") forState:UIControlStateNormal];
    [_aboutUsButton setTitle:NSLocalizedString(@"Higashi Dance Network", @"Higashi Dance Network") forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
    _aboutUsButton = nil;
    _tweetButton = nil;
    _titleLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[MixpanelAPI sharedAPI] track:@"Info Page Shown"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
