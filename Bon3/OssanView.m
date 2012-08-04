//
//  OssanView.m
//  Bon3
//
//  Created by Asano Satoshi on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OssanView.h"
@implementation OssanView {
    UIImage *_landingOssanImage;
    NSArray *_ossanImages;
}

- (id)init
{
    self = [super init];
    if (self) {
        _landingOssanImage = [UIImage imageNamed:@"appimage1"];
        _ossanImages = @[[UIImage imageNamed:@"appimage2"], 
                        [UIImage imageNamed:@"appimage3"],
                        [UIImage imageNamed:@"appimage4"],
                        [UIImage imageNamed:@"appimage5"],
                        [UIImage imageNamed:@"appimage6"]];
        self.contents = (__bridge id)_landingOssanImage.CGImage;
    }
    return self;
}


-(void)changeImage {
    UIImage *image = [_ossanImages objectAtIndex:arc4random() % _ossanImages.count];
    [CATransaction begin];
    [CATransaction setDisableActions:YES]; // disable implicit animation
    self.contents = (__bridge id)image.CGImage;
    [CATransaction commit];
}

-(void)landing {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];  // disable implicit animation
    self.contents = (__bridge id)_landingOssanImage.CGImage;
    [CATransaction commit];
}

@end
