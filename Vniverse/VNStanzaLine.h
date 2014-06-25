//
//  VNStanzaLine.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VNStanzaLine : NSObject

- (id) initWithLetters:(NSArray *)textLetters andYPosition:(CGFloat)yPosition andView:(UIView *)view;
- (void) selfDestruct;

@property (nonatomic) NSArray *letters;
@property (nonatomic) NSArray *lineLetters;
@property (nonatomic) CGFloat lineWidth;

@end