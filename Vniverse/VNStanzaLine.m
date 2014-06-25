//
//  VNStanzaLine.m
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNStanzaLine.h"
#import "VNStanzaLetter.h"

@implementation VNStanzaLine

@synthesize letters, lineLetters, lineWidth;

- (id) initWithLetters:(NSArray *)textLetters andYPosition:(CGFloat)yPosition andView:(UIView *)view {
    
    BOOL isItalic = NO;
    NSMutableArray *ls = [NSMutableArray array];
    if(self = [super init]) {
        for(int i=0; i<[textLetters count]; i++){
            NSString *str = textLetters[i];
            if([str isEqualToString:@"^"]) {
                isItalic = isItalic ? NO : YES;
                continue;
            }
            VNStanzaLetter *l = [[VNStanzaLetter alloc] initWithFrame:CGRectMake(0, yPosition, 20, 10) letter:textLetters[i] view:view italic:isItalic];
            [ls addObject:l];
        }
        self.lineLetters = [NSArray arrayWithArray:ls];
        [self setLetterPositions];
    }
    return self;
}



- (void) setLetterPositions {
    
    NSArray *xPositions = [self wordsXPositions];
    
    for(int i=0; i<[self.lineLetters count]; i++) {
        VNStanzaLetter *l = self.lineLetters[i];
        [l setXPosition:[xPositions[i] floatValue]];
        [l animateIn];
    }
}


- (NSArray *) wordsXPositions {
    
    CGFloat total = 0;
    NSMutableArray *xPositions = [[NSMutableArray alloc] initWithCapacity:[self.lineLetters count]];
    
    for(int i=0; i<[self.lineLetters count]; i++){
        
        VNStanzaLetter *w = [self.lineLetters objectAtIndex:i];
        CGFloat wordWidth = [w width];
        [xPositions addObject:[NSNumber numberWithFloat:total]];
        total += wordWidth;
    }
    
    self.lineWidth = total;
    
    for(int i=0; i<[xPositions count]; i++){
        CGFloat x = [xPositions[i] floatValue];
        xPositions[i] = [NSNumber numberWithFloat:(x)];
    }
    
    NSArray *result = [xPositions copy];
    return result;
}



- (void) selfDestruct {
    
    for(int i=0; i<[self.lineLetters count]; i++) {
        VNStanzaLetter *l = self.lineLetters[i];
        [l selfDestruct];
    }
}


@end
