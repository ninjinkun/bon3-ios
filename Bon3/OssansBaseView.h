//
//  OssansBaseVIew.h
//  Bon3
//
//  Created by Asano Satoshi on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#define OSSAN_SIDE_MARGIN 10
#define OSSAN_TOP_MARGIN 10
#define OSSAN_BOTTOM_MARGIN 10
@interface OssansBaseView : UIView
@property (nonatomic) NSInteger ossansCount;
@property (nonatomic, strong) NSArray *ossanHeights;           
@property (nonatomic, strong) UIColor *ossanColor;
-(void)setOssansCount:(NSInteger)ossansCount animated:(BOOL)animated;
@end
