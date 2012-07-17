//
//  InfoViewController.m
//  Bon3
//
//  Created by Asano Satoshi on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"
#import <Twitter/Twitter.h>
@interface InfoViewController ()

@end

@implementation InfoViewController

@synthesize screenImage = _screenImage;
@synthesize tweetButton = _tweetButton;

-(IBAction)twitterButtonPushed:(id)sender {        
    TWTweetComposeViewController *twitterViewController = [[TWTweetComposeViewController alloc] init];
    if (_screenImage) 
        [twitterViewController addImage:_screenImage];    
    [twitterViewController setInitialText:NSLocalizedString(@"Dancing with #bon3", @"Twieet Text")];
    [twitterViewController addURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/bon3/"]];
    [twitterViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result){
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:twitterViewController animated:YES completion:nil];
}

-(IBAction)aboutUsButtonPushed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/bon3/"]];
}

-(IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tweetButton.enabled = [TWTweetComposeViewController canSendTweet];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
