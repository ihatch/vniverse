//
//  VNConstellationView.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/12/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNConstellationView : UIView

@property (nonatomic) NSMutableArray *constellationStarIDs;
@property (nonatomic) NSMutableArray *starViews;
@property NSValue *drawingFingerPoint;

- (void) deactivate;
- (void) addStarView:(UIView *)star;

@end
