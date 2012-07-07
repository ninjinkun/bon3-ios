//
//  OssanView.m
//  Bon3
//
//  Created by Asano Satoshi on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OssanView.h"
#import <QuartzCore/QuartzCore.h>
@implementation OssanView {
    UIImage *_landingOssanImage;
    NSArray *_ossanImages;
    CALayer *_ossanImageLayer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _landingOssanImage = [UIImage imageNamed:@"appimage1"];
        _ossanImages = [NSArray arrayWithObjects:
                        [UIImage imageNamed:@"appimage2"], 
                        [UIImage imageNamed:@"appimage3"],
                        [UIImage imageNamed:@"appimage4"],
                        [UIImage imageNamed:@"appimage5"],
                        [UIImage imageNamed:@"appimage6"],
                        nil];
        _ossanImageLayer = [CALayer layer];
        _ossanImageLayer.frame = self.bounds;
        _ossanImageLayer.contents = (__bridge id)_landingOssanImage.CGImage;
        [self.layer addSublayer:_ossanImageLayer];
    }
    return self;
}

-(void)changeImage {
    UIImage *image = [_ossanImages objectAtIndex:rand() % _ossanImages.count];
    _ossanImageLayer.contents = (__bridge id)image.CGImage;
}

-(void)landing {
    _ossanImageLayer.contents = (__bridge id)_landingOssanImage.CGImage;
}

@end
