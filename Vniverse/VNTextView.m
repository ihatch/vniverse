//
//  VNTextView.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/13/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNTextView.h"
#import "VNStar.h"
#import "VNWord.h"
#import "VNTercet.h"
#import "VNData.h"

VNTercet *activeTercet;
VNTercet *secondaryTercet;
NSMutableArray *numberLabels;

@implementation VNTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
    }
    return self;
}


- (void) showNumberForStar:(int)starID {
    
    CGPoint coords = [VNData coordinatesForStar:starID];
    CGRect wordRect = CGRectMake(coords.x + 10, coords.y - 20, 10, 10);
    NSString *str = [NSString stringWithFormat:@"%d", starID];
    
    VNWord *newWord = [[VNWord alloc] initWithFrame:wordRect string:str starID:starID size:12 colorize:NO];
    [newWord selfDestructAfterXSeconds:5];
    
    [self addSubview:newWord];
    [[self superview] bringSubviewToFront:self];
}

- (void) showWordInColorForStar:(int)starID {
    CGPoint coords = [VNData coordinatesForStar:starID];
    
    if(starID == 28) coords.x -= 50;
    if(starID == 28) coords.y -= 10;
    if(starID == 42) coords.x -= 25;
    if(starID == 42) coords.y -= 10;
    if(starID == 154) coords.x -= 65;
    
    CGRect wordRect = CGRectMake(coords.x + 15, coords.y - 30, 10, 10);
    
    VNWord *newWord = [[VNWord alloc] initWithFrame:wordRect string:[VNData wordForStar:starID] starID:starID size:15 colorize:YES];
    [newWord selfDestructAfterXSeconds:5];
    
    [self addSubview:newWord];
    [[self superview] bringSubviewToFront:self];

    
}



- (void) showAllNumbers {
    for(int i=1; i<233; i++){
        [self showNumberForStar:i];
    }
}


- (void) showWordForStar:(int)starID selfDestructAfter:(CGFloat)after {
    
    CGPoint coords = [VNData coordinatesForStar:starID];

    if(starID == 28) coords.x -= 50;
    if(starID == 28) coords.y -= 10;
    if(starID == 42) coords.x -= 25;
    if(starID == 42) coords.y -= 10;
    if(starID == 154) coords.x -= 65;

    CGRect wordRect = CGRectMake(coords.x + 15, coords.y - 30, 10, 10);

    VNWord *newWord = [[VNWord alloc] initWithFrame:wordRect string:[VNData wordForStar:starID] starID:starID size:15 colorize:NO];
    [newWord selfDestructAfterXSeconds:after];
    
    [self addSubview:newWord];
    [[self superview] bringSubviewToFront:self];

}


- (void) showWordForStar:(int)starID {
    [self showWordForStar:starID selfDestructAfter:5];
}



- (void) showQuickWordForStar:(int)starID {
    [self showWordForStar:starID selfDestructAfter:2];
}


- (void) clearAllText {
    [self clearTercet];
    for (UIView *v in self.subviews) {
        if([v isKindOfClass:[VNWord class]]) {
            VNWord *w = (VNWord *)v;
            [w selfDestruct];
        }
    }
}



- (void) showTercet:(int)tercet {

    if(activeTercet) [activeTercet selfDestruct];
    if(secondaryTercet) [secondaryTercet selfDestruct];
 
    CGPoint point = [VNData coordinatesForStar:tercet];
    
//    if(point.y > 600) point.y -= 100;
//    if(point.x > 900) point.x -= 100;
//    if(point.x > 900) point.x -= 100;
    
    activeTercet = [[VNTercet alloc] initWithFrame:CGRectMake(point.x + 13, point.y - 34, 200, 100) andTercet:tercet];

    [self addSubview:activeTercet];
    [self bringSubviewToFront:activeTercet];
    [[self superview] bringSubviewToFront:self];
}


- (void) showTwoTercets:(int)a and:(int)b {
    
    CGPoint pointA = [VNData coordinatesForStar:a];
    CGPoint pointB = [VNData coordinatesForStar:b];
    
    activeTercet = [[VNTercet alloc] initWithFrame:CGRectMake(pointA.x + 13, pointA.y - 34, 200, 100) andTercet:a];
    secondaryTercet = [[VNTercet alloc] initWithFrame:CGRectMake(pointB.x + 13, pointB.y - 34, 200, 100) andTercet:b];
    
    [self addSubview:activeTercet];
    [self addSubview:secondaryTercet];
    [self bringSubviewToFront:activeTercet];
    [self bringSubviewToFront:secondaryTercet];

    [[self superview] bringSubviewToFront:self];
    
}



- (void) clearTercet {
    if(activeTercet) [activeTercet selfDestruct];
    if(secondaryTercet) [secondaryTercet selfDestruct];
}



@end
