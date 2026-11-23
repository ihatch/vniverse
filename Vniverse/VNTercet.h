//
//  VNTercet.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VNTercet : UIView

@property (nonatomic) CGFloat tercetWidth;

// origin: top-left of the tercet block. scale: text scale. area: the part of
// the containing view the tercet must stay inside (clear of the Dynamic
// Island, notch and rounded screen corners).
- (id) initWithOrigin:(CGPoint)origin tercet:(int)starNumber scale:(CGFloat)scale area:(CGRect)area;
- (void) selfDestruct;
- (void) selfDestructAfterXSeconds:(CGFloat)seconds;


@end
