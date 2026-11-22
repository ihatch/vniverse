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

// origin: top-left of the tercet block. scale: text scale. bounds: size of the
// containing view, used to keep the whole tercet on screen.
- (id) initWithOrigin:(CGPoint)origin tercet:(int)starNumber scale:(CGFloat)scale bounds:(CGSize)bounds;
- (void) selfDestruct;
- (void) selfDestructAfterXSeconds:(CGFloat)seconds;


@end
