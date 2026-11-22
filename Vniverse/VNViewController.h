//
//  VNViewController.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface VNViewController : UIViewController <WKNavigationDelegate>

+ (void) suspendTimers;
+ (void) resumeTimers;

@end
