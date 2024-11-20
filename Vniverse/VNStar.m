//
//  VNStar.m
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNStar.h"
#import "VNData.h"

@implementation VNStar {
    BOOL highlight;
    double starRadius;
    BOOL isHidden;
}


- (id) initWithFrame:(CGRect)frame starID:(int)starID x:(int)starX y:(int)starY {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
        CGFloat adjX = starX * 1;
        CGFloat adjY = starY * 1;
        self.center = CGPointMake(adjX, adjY);
        self.tag = starID;
        self.userInteractionEnabled = YES;
        starRadius = (drand48() * 2) + 1;
    }
    return self;
}


- (void) addHighlight {
    highlight = YES;
    [self setNeedsDisplay];
}

- (void) removeHighlight {
    highlight = NO;
    [self setNeedsDisplay];
}

- (void) hideStar {
    
    if(isHidden) return;
    isHidden = true;
    
    CGFloat duration = 3 + ABF(3);
    CGFloat delay = ABF(3);
    
    [UIView animateWithDuration:duration delay:delay options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        
        CGFloat duration = 3 + ABF(6);
        CGFloat delay = ABF(2);

        [UIView animateWithDuration:duration delay:delay options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
            self->isHidden = false;
        }];
    }];
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    
    CGContextBeginPath(context);
    CGContextAddArc(context, 6, 6, starRadius, 0, 2*M_PI, YES);
    CGContextClosePath(context);
    
    if(!highlight) {
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.6);
    } else {
        CGContextSetRGBFillColor(context, 0.5, 0.5, 1.0, 0.6);
    }
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {0.72, 0.7, 0.71, 0.7};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextDrawPath(context, kCGPathFillStroke);

    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
}

@end
