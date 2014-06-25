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
}

@synthesize tercetWidth;

- (id) initWithFrame:(CGRect)frame andTercet:(int)starNumber {
    if(self = [super initWithFrame:frame]) {
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
    numberLabel = [[VNWord alloc] initWithFrame:wordRect string:str starID:starID size:12 colorize:YES];
    [self addSubview:numberLabel];

}

- (void) initWord {
    CGRect wordRect = CGRectMake(0, 18, 10, 10);
    wordLabel = [[VNWord alloc] initWithFrame:wordRect string:[VNData wordForStar:starID] starID:starID size:15 colorize:YES];
    [self addSubview:wordLabel];
}


- (void) initLines {
    
    int y = 40;
    for(int i=0; i<[tercetText count]; i++) {
        NSString *str = tercetText[i];
        NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[str length]];
        for (int i=0; i < [str length]; i++) {
            NSString *ichar  = [NSString stringWithFormat:@"%c", [str characterAtIndex:i]];
            [characters addObject:ichar];
        }
        VNStanzaLine *line = [[VNStanzaLine alloc] initWithLetters:characters andYPosition:y andView:self];
        if(line.lineWidth > self.tercetWidth) self.tercetWidth = line.lineWidth;
        [lines addObject:line];
        y += 22;
    }
    
    // check location to avoid clipping
    CGFloat totalX = self.frame.origin.x + self.tercetWidth;
    CGFloat totalY = self.frame.origin.y + 66;

    if(totalX > 1024) {
        CGFloat offsetX = 1024 - totalX - 10;
        self.frame = CGRectOffset(self.frame, offsetX, 0);
    }

    if(totalY > 630) {
        CGFloat offsetY = 630 - totalY - 12;
        self.frame = CGRectOffset(self.frame, 0, offsetY);
    }
}


- (void) selfDestructAfterXSeconds:(CGFloat)seconds {
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(selfDestruct) userInfo:nil repeats:NO];
}


- (void) selfDestruct {
    if(numberLabel) [numberLabel selfDestruct];
    if(wordLabel) [wordLabel selfDestruct];
    for(int i=0; i<3; i++) {
        [lines[i] selfDestruct];
    }
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(die) userInfo:nil repeats:NO];
}


- (void) die {
    [self removeFromSuperview];
}



@end
