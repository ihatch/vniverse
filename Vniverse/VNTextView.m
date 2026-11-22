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

static VNTercet *activeTercet;
static VNTercet *secondaryTercet;

@implementation VNTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        _fieldOrigin = CGPointZero;
        _textScale = 1.0;
    }
    return self;
}

- (BOOL)canBecomeFocused {
    return NO;
}



////////////////
// POSITIONS //
////////////////

// Where a star appears, in this view's coordinates.
- (CGPoint) pointForStar:(int)starID {
    CGPoint p = [VNData pointForStar:starID];
    return CGPointMake(self.fieldOrigin.x + p.x, self.fieldOrigin.y + p.y);
}

// Where a star's word label starts. Offsets are in text units, so they grow
// and shrink with the text.
- (CGRect) wordRectForStar:(int)starID {
    CGFloat dx = 15, dy = -30;
    if(starID == 28) { dx -= 50; dy -= 10; }
    if(starID == 42) { dx -= 25; dy -= 10; }
    if(starID == 154) dx -= 65;

    CGPoint p = [self pointForStar:starID];
    return CGRectMake(p.x + dx * self.textScale, p.y + dy * self.textScale, 10, 10);
}

// Nudge a label so it is fully visible.
- (void) keepOnScreen:(UIView *)v {
    CGRect f = v.frame;
    CGFloat margin = 6;
    CGSize size = self.bounds.size;
    if (CGRectGetMaxX(f) > size.width - margin) f.origin.x = size.width - margin - f.size.width;
    if (f.origin.x < margin) f.origin.x = margin;
    if (CGRectGetMaxY(f) > size.height) f.origin.y = size.height - f.size.height;
    if (f.origin.y < 0) f.origin.y = 0;
    v.frame = f;
}

- (void) addLabel:(VNWord *)word {
    [self keepOnScreen:word];
    [self addSubview:word];
    [[self superview] bringSubviewToFront:self];
}



///////////
// WORDS //
///////////

- (void) showNumberForStar:(int)starID {
    CGPoint p = [self pointForStar:starID];
    CGRect rect = CGRectMake(p.x + 10 * self.textScale, p.y - 20 * self.textScale, 10, 10);
    NSString *str = [NSString stringWithFormat:@"%d", starID];

    VNWord *newWord = [[VNWord alloc] initWithFrame:rect string:str starID:starID size:12 colorize:NO scale:self.textScale];
    [newWord selfDestructAfterXSeconds:5];
    [self addLabel:newWord];
}

- (void) showWordInColorForStar:(int)starID {
    VNWord *newWord = [[VNWord alloc] initWithFrame:[self wordRectForStar:starID] string:[VNData wordForStar:starID] starID:starID size:15 colorize:YES scale:self.textScale];
    [newWord selfDestructAfterXSeconds:5];
    [self addLabel:newWord];
}

- (void) showAllNumbers {
    for(int i=1; i<233; i++){
        [self showNumberForStar:i];
    }
}

- (void) showWordForStar:(int)starID selfDestructAfter:(CGFloat)after {
    VNWord *newWord = [[VNWord alloc] initWithFrame:[self wordRectForStar:starID] string:[VNData wordForStar:starID] starID:starID size:15 colorize:NO scale:self.textScale];
    [newWord selfDestructAfterXSeconds:after];
    [self addLabel:newWord];
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
            [(VNWord *)v selfDestruct];
        }
    }
}



/////////////
// TERCETS //
/////////////

- (VNTercet *) newTercetForStar:(int)tercet {
    CGPoint p = [self pointForStar:tercet];
    CGPoint origin = CGPointMake(p.x + 13 * self.textScale, p.y - 34 * self.textScale);
    return [[VNTercet alloc] initWithOrigin:origin tercet:tercet scale:self.textScale bounds:self.bounds.size];
}

- (void) showTercet:(int)tercet {
    [self clearTercet];

    activeTercet = [self newTercetForStar:tercet];
    [self addSubview:activeTercet];
    [[self superview] bringSubviewToFront:self];
}

- (void) showTwoTercets:(int)a and:(int)b {
    [self clearTercet];

    activeTercet = [self newTercetForStar:a];
    secondaryTercet = [self newTercetForStar:b];
    [self addSubview:activeTercet];
    [self addSubview:secondaryTercet];
    [[self superview] bringSubviewToFront:self];
}

- (void) clearTercet {
    if(activeTercet) [activeTercet selfDestruct];
    if(secondaryTercet) [secondaryTercet selfDestruct];
    activeTercet = nil;
    secondaryTercet = nil;
}

@end
