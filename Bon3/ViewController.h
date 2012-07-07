//
//  ViewController.h
//  Bon3
//
//  Created by Asano Satoshi on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVGKit.h"

@interface ViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet SVGView *contentView;

@end
