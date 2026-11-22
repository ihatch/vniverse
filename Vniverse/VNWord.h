//
//  VNWord.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/22/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface VNWord : UILabel

- (id) initWithFrame:(CGRect)frame string:(NSString *)string starID:(int)starID size:(CGFloat)size colorize:(BOOL)colorize;
// size is the nominal point size; scale multiplies it for the current screen.
- (id) initWithFrame:(CGRect)frame string:(NSString *)string starID:(int)starID size:(CGFloat)size colorize:(BOOL)colorize scale:(CGFloat)scale;
- (void) selfDestructAfterXSeconds:(CGFloat)seconds;
- (void) selfDestruct;

@end
