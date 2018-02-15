//
//  VNWord.m
//  Vniverse
//
//  Created by Ian Hatcher on 1/22/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNWord.h"
#import "VNData.h"

@implementation VNWord {
    CGPoint startPoint;
    CGFloat wordWidth;
    BOOL dead;
}

- (id)initWithFrame:(CGRect)frame string:(NSString *)string starID:(int)starID size:(CGFloat)size colorize:(BOOL)colorize {
    if(self = [super initWithFrame:frame]) {

        dead = NO;
        self.userInteractionEnabled = NO;
        
        self.font = [UIFont fontWithName:@"EuphemiaUCAS" size:size];
        self.text = string;

        // Non-star labels
        if(starID == 0) {
            self.textAlignment = NSTextAlignmentCenter;
        } else {
            [self resizeFrameToFitString];
        }

        
        if(colorize) {
            self.textColor = [VNData colorForStar:starID];
        } else {
            self.textColor = [UIColor colorWithRed:0.8 green:0.88 blue:0.97 alpha:1];
        }
        
        // Numbers...
        if(size == 12) self.textColor = [UIColor colorWithWhite:0.75 alpha:1];
        
        self.shadowOffset = CGSizeMake(1, 1);
        self.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
        self.alpha = 0;

        [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = 1.0;
        } completion:^(BOOL finished) {}];
    }
    
    return self;
}

- (void) resizeFrameToFitString {
    CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];
    CGRect frame = self.frame;
    frame.size = size;
    frame.size.height = frame.size.height + 6;
    self.frame = frame;
    wordWidth = frame.size.width;
}

- (void) selfDestructAfterXSeconds:(CGFloat)seconds {
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(selfDestruct) userInfo:nil repeats:NO];
}


- (void) selfDestruct {
    if(dead) return;
    dead = YES;
    [UIView animateWithDuration:2.5 delay:0 options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
