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

-(IBAction)twitterButtonPushed:(id)sender {
    TWTweetComposeViewController *twitterViewController = [[TWTweetComposeViewController alloc] init];
    [twitterViewController addImage:_screenImage];
    [twitterViewController setInitialText:NSLocalizedString(@"Dancing with #bon3", @"Twieet Text")];
    [twitterViewController addURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/bon3/"]];
    [self presentViewController:twitterViewController animated:YES completion:nil];
}

-(IBAction)aboutUsButtonPushed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://higashi-dance-network.appspot.com/"]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
