//
//  VNModalView.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNBlackCurtain : UIView

- (instancetype) initWithFrame:(CGRect)frame;
- (void) show;
- (void) hide;
- (void) hideWithDuration:(NSTimeInterval)duration;

// Called once the curtain has faded out and been removed.
@property (nonatomic, copy) void (^didHide)(void);

@end
