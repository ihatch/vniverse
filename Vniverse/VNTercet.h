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

- (id) initWithFrame:(CGRect)frame andTercet:(int)starNumber;
- (void) selfDestruct;
- (void) selfDestructAfterXSeconds:(CGFloat)seconds;


@end
