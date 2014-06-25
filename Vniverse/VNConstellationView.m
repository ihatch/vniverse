//
//  VNConstellationView.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNConstellationView.h"

@implementation VNConstellationView

@synthesize starViews, drawingFingerPoint;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.starViews = [NSMutableArray array];
    }
    return self;
}


- (void) deactivate {
    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (void) drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {0.5, 0.5, 0.7, 0.8};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    
    CGPoint from;
    UIView *lastStar;
    for (UIView *star in self.starViews) {
        from = star.center;
        if (lastStar) {
            CGContextAddLineToPoint(context, from.x, from.y);
        } else {
            CGContextMoveToPoint(context, from.x, from.y);
        }
        lastStar = star;
    }
    
//    if(self.drawingFingerPoint != nil) {
//        CGPoint pt = [self.drawingFingerPoint CGPointValue];
//        CGContextAddLineToPoint(context, pt.x, pt.y);
//        self.drawingFingerPoint = nil;
//    }
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
}


- (void) addStarView:(UIView *)star {
    if (!self.starViews) self.starViews = [NSMutableArray array];
    [self.starViews addObject:star];
}

@end
