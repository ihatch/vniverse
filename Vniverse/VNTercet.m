//
//  VNTercet.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNTercet.h"
#import "VNStanzaLine.h"
#import "VNStanzaLetter.h"
#import "VNData.h"
#import "VNWord.h"

@implementation VNTercet {
    int starID;
    NSArray *tercetText;
    NSMutableArray *lines;
    VNWord *numberLabel;
    VNWord *wordLabel;
    CGFloat scale;
    CGSize containerSize;
}

@synthesize tercetWidth;

- (id) initWithOrigin:(CGPoint)origin tercet:(int)starNumber scale:(CGFloat)textScale bounds:(CGSize)bounds {
    if(self = [super initWithFrame:CGRectMake(origin.x, origin.y, 200 * textScale, 100 * textScale)]) {
        scale = textScale;
        containerSize = bounds;
        self.tercetWidth = 0;
        starID = starNumber;
        lines = [NSMutableArray array];
        tercetText = [VNData tercetAtIndex:starNumber];
        [self initNumber];
        [self initWord];
        [self initLines];
    }
    return self;
}

- (void) initNumber {
    CGRect wordRect = CGRectMake(0, 0, 10, 10);
    NSString *str = [NSString stringWithFormat:@"%d", starID];
    numberLabel = [[VNWord alloc] initWithFrame:wordRect string:str starID:starID size:12 colorize:YES scale:scale];
    [self addSubview:numberLabel];

}

- (void) initWord {
    CGRect wordRect = CGRectMake(0, 18 * scale, 10, 10);
    wordLabel = [[VNWord alloc] initWithFrame:wordRect string:[VNData wordForStar:starID] starID:starID size:15 colorize:YES scale:scale];
    [self addSubview:wordLabel];
}


- (void) initLines {
    
    CGFloat y = 40 * scale;
    for(int i=0; i<[tercetText count]; i++) {
        NSString *str = tercetText[i];
        // Split into whole characters. (The old "%c" format kept only the low
        // byte of each character, which dropped or garbled curly quotes,
        // accented letters and other non-ASCII text.)
        NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[str length]];
        [str enumerateSubstringsInRange:NSMakeRange(0, [str length])
                                options:NSStringEnumerationByComposedCharacterSequences
                             usingBlock:^(NSString *ch, NSRange r, NSRange er, BOOL *stop) {
            [characters addObject:ch];
        }];
        VNStanzaLine *line = [[VNStanzaLine alloc] initWithLetters:characters andYPosition:y andView:self scale:scale];
        if(line.lineWidth > self.tercetWidth) self.tercetWidth = line.lineWidth;
        [lines addObject:line];
        y += 22 * scale;
    }
    
    // Keep the whole tercet inside the containing view.
    CGRect f = self.frame;
    CGFloat blockHeight = 110 * scale;
    CGFloat margin = 8;
    if (f.origin.x + self.tercetWidth > containerSize.width - margin) f.origin.x = containerSize.width - margin - self.tercetWidth;
    if (f.origin.x < margin) f.origin.x = margin;
    if (f.origin.y + blockHeight > containerSize.height - margin) f.origin.y = containerSize.height - margin - blockHeight;
    if (f.origin.y < 0) f.origin.y = 0;
    self.frame = f;
}


- (void) selfDestructAfterXSeconds:(CGFloat)seconds {
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(selfDestruct) userInfo:nil repeats:NO];
}


- (void) selfDestruct {
    if(numberLabel) [numberLabel selfDestruct];
    if(wordLabel) [wordLabel selfDestruct];
    for (VNStanzaLine *line in lines) {
        [line selfDestruct];
    }
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(die) userInfo:nil repeats:NO];
}


- (void) die {
    [self removeFromSuperview];
}



@end
