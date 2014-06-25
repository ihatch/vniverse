//
//  VNModalView.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNBlackCurtain.h"

@implementation VNBlackCurtain

BOOL ready;

- (id) init {
    self = [super initWithFrame:CGRectMake(0, 0, 1024, 768)];
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
        ready = YES;
    }];
}

- (void) hide {
    [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
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
