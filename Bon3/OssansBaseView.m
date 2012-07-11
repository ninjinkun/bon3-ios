//
//  OssansBaseVIew.m
//  Bon3
//
//  Created by Asano Satoshi on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OssansBaseView.h"
#import <QuartzCore/QuartzCore.h>
#import "OssanView.h"
@implementation OssansBaseView {
    NSArray *_ossanViews;    
}
@synthesize ossansCount = _ossansCount;
@synthesize ossanHeights = _ossanHeights;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

-(void)layoutSubviews {
    for (int i = 0; i < _ossansCount; i++) {
        OssanView *ossan = [_ossanViews objectAtIndex:i];        
        CGRect frame = ossan.frame;
        CGFloat width = self.frame.size.width / _ossansCount;
        CGFloat height = ossan.frame.size.height * (width / ossan.frame.size.width);
        frame.size = CGSizeMake(width, height);
        frame.origin.x = width * i;
        ossan.frame = frame;
    }
}

-(void)setOssansCount:(NSInteger)ossansCount {
    if (_ossansCount != ossansCount) {
        [_ossanViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        NSMutableArray *ossanViews = [NSMutableArray array];        
        for (int i = 0; i < ossansCount; i++) {
            CGRect frame = CGRectZero;
            frame.size = [UIImage imageNamed:@"appimage1"].size;
            OssanView *view = [[OssanView alloc] initWithFrame:frame];
            [ossanViews addObject:view];
            [self addSubview:view];            
        }
        _ossanViews = [ossanViews copy];
    }
    _ossansCount = ossansCount;
}

-(void)setOssanHeights:(NSArray *)ossanHeights {
    for (int i = 0; i < _ossansCount; i++) {
        if (i < ossanHeights.count) break;
        OssanView *ossan = [_ossanViews objectAtIndex:i];        
        CGRect frame = ossan.frame;
        CGFloat height = [[ossanHeights objectAtIndex:i] floatValue];
        if (height == 0) {
            [ossan landing];
        }
        else {
            [ossan changeImage];
        }
        frame.origin.y = height;
        ossan.frame = frame;        
    }
}

@end
