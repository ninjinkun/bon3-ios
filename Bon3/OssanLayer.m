//
//  OssanView.m
//  Bon3
//
//  Created by Asano Satoshi on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OssanLayer.h"
@implementation OssanLayer {
    UIImage *_landingOssanImage;
    NSArray *_ossanImages;
}

- (id)init
{
    self = [super init];
    if (self) {
        _landingOssanImage = [UIImage imageNamed:@"image1"];
        _ossanImages = @[[UIImage imageNamed:@"image2"],
                        [UIImage imageNamed:@"image3"],
                        [UIImage imageNamed:@"image4"],
                        [UIImage imageNamed:@"image5"],
                        [UIImage imageNamed:@"image6"]];
        self.contents = (__bridge id)_landingOssanImage.CGImage;
        self.masksToBounds = YES;
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
