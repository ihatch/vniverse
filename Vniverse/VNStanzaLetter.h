//
//  VNStanzaLetter.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNStanzaLetter : UILabel

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGFloat width;

- (id) initWithFrame:(CGRect)frame letter:(NSString *)letter view:(UIView *)view italic:(BOOL)italic;
- (void) setXPosition:(CGFloat)x;
- (void) animateIn;
- (void) selfDestruct;

@end
