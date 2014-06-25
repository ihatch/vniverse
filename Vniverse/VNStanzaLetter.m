//
//  VNStanzaLetter.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNStanzaLetter.h"
#import "VNData.h"

@implementation VNStanzaLetter

@synthesize width, startPoint;
UIView *view;

- (id) initWithFrame:(CGRect)frame letter:(NSString *)letter view:(UIView *)view italic:(BOOL)italic {
    if(self = [super initWithFrame:frame]) {
        self.text = letter;
        if([letter isEqualToString:@"_"]) {
            unichar ch = 0x2014;
            NSString *emdash = [NSString stringWithCharacters:&ch length:1];
            self.text = emdash;
        }
        if(italic) {
            self.font = [UIFont fontWithName:@"EuphemiaUCAS-italic" size:15];
        } else {
            self.font = [UIFont fontWithName:@"EuphemiaUCAS" size:15];
        }
        self.textColor = [UIColor colorWithWhite:1.0 alpha:1];
        self.shadowColor = [UIColor colorWithWhite:0 alpha:0.9];
        self.shadowOffset = CGSizeMake(1, 1);
        [self resizeFrameToFitString];
        self.alpha = 0;
        self.userInteractionEnabled = NO;
        [view addSubview:self];
    }
    
    return self;
}

- (void) resizeFrameToFitString {
    CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];
    CGRect frame = self.frame;
    frame.size = size;
    frame.size.height = frame.size.height + 10;
    self.frame = frame;
    self.width = size.width;
}

- (void) animateIn {
    CGFloat randomDelay = ABF(0.8);
    CGFloat randomDuration = 1 + ABF(1.8);
    [UIView animateWithDuration:randomDuration delay:randomDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1.0;
        self.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(BOOL finished) {}];
}


- (CGFloat) convertLeftToCenter:(CGFloat)x {
    CGFloat r = x + (self.width / 2);
    return r;
}

- (void) setXPosition:(CGFloat)x {
    startPoint = self.center;
    CGPoint newPoint = CGPointMake([self convertLeftToCenter:x], self.center.y);
    self.center = newPoint;
}


- (void) selfDestruct {
    
    CGFloat randomDelay = ABF(0.8);
    CGFloat randomDuration = 1 + ABF(1.8);
    
    [UIView animateWithDuration:randomDuration delay:randomDelay options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        view = nil;
    }];
}


@end
