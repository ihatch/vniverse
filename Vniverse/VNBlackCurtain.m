//
//  VNModalView.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNBlackCurtain.h"

@implementation VNBlackCurtain {
    BOOL ready;
}

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    }
    return self;
}

- (void) show {
    [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        self->ready = YES;
    }];
}

- (void) hide {
    [self hideWithDuration:0.7];
}

- (void) hideWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (self.didHide) self.didHide();
    }];
}



- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [[event allTouches] anyObject];
    if (![touch.view isKindOfClass:[VNBlackCurtain class]]) {
        return;
    }
    if(ready) [self hide];
}


@end
