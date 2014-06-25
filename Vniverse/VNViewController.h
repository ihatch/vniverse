//
//  VNViewController.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNViewController : UIViewController <UIScrollViewDelegate, UIWebViewDelegate>

@property NSTimer *backgroundTimer;

+ (void) suspendTimers;
+ (void) resumeTimers;
+ (void) slowFadeBackground;

@end
