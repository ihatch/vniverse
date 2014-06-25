//
//  VNStar.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNStar : UIView

- (id) initWithFrame:(CGRect)frame starID:(int)starID x:(int)starX y:(int)starY;
- (void) addHighlight;
- (void) removeHighlight;
- (void) hideStar;

@end
