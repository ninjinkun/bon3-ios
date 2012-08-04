//
//  OssansBaseVIew.m
//  Bon3
//
//  Created by Asano Satoshi on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OssansBaseView.h"
#import <QuartzCore/QuartzCore.h>
#import "OssanLayer.h"
@implementation OssansBaseView {
    NSArray *_ossanViews;    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.ossanColor = [UIColor colorWithRed: 1.0 green: 0.3671875 blue: 0.58984375 alpha: 1.0];
    }
    return self;
}

-(void)setOssanColor:(UIColor *)ossanColor {
    _ossanColor = ossanColor;
    [CATransaction begin];
    [CATransaction setDisableActions:YES]; // disable implicit animation
    for (int i = 0; i < _ossansCount; i++) {
        OssanLayer *ossan = [_ossanViews objectAtIndex:i];         
        ossan.backgroundColor = _ossanColor.CGColor;
    }
    [CATransaction commit];
}

-(void)layoutSubviews {
    for (int i = 0; i < _ossansCount; i++) {
        OssanLayer *ossan = [_ossanViews objectAtIndex:i];
        CGRect frame = ossan.frame;
        CGFloat width = self.frame.size.width / _ossansCount;
        CGFloat height = floorf(ossan.frame.size.height * (width / ossan.frame.size.width));
        frame.size = CGSizeMake(width, (int)height);
        frame.origin.x = width * i;
        frame.origin.y = self.frame.size.height - height;
        ossan.frame = frame;
//        NSLog(@"ossan content %@", NSStringFromCGRect(ossan.contentsRect));
//        NSLog(@"ossan frame %@",  NSStringFromCGRect(frame));        
    }
}

-(void)setOssansCount:(NSInteger)ossansCount {
    if (_ossansCount != ossansCount) {
        [_ossanViews makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        NSMutableArray *ossanViews = [NSMutableArray array];        
        for (int i = 0; i < ossansCount; i++) {
            CGRect frame = CGRectZero;
            frame.size = [UIImage imageNamed:@"appimage1"].size;

            OssanLayer *view = [[OssanLayer alloc] init];
            view.frame = frame;
            view.backgroundColor = _ossanColor.CGColor;
            [ossanViews addObject:view];
            [self.layer addSublayer:view];
        }
        _ossanViews = [ossanViews copy];
    }
    _ossansCount = ossansCount;
}

-(void)setOssanHeights:(NSArray *)ossanHeights {
    [CATransaction begin];
    [CATransaction setDisableActions:YES]; // disable implicit animation
    for (int i = 0; i < _ossansCount; i++) {
        if (i > ossanHeights.count) break;
        OssanLayer *ossan = [_ossanViews objectAtIndex:i];        
        CGRect frame = ossan.frame;
        CGFloat height = ([[ossanHeights objectAtIndex:i] floatValue] / 500000) * (i + 1);
        height = height > 10 ? height : 0;
        if (height == 0) {
            [ossan landing];
        }
        else {
            [ossan changeImage];
        }
        frame.origin.y = self.frame.size.height - frame.size.height - height;
        ossan.frame = frame;        
    }
    [CATransaction commit];
}

@end
