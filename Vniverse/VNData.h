//
//  VNData.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/20/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <Foundation/Foundation.h>

CGFloat ABF(CGFloat multiplier);
int ABI(int max);

@interface VNData : NSObject

+ (int) tercetCount;
+ (NSArray *) tercetAtIndex:(int)t;
+ (CGPoint) coordinatesForStar:(int)n;
+ (NSString *) wordForStar:(int)n;
+ (NSString *) constellationForStar:(int)n;
+ (NSArray *) mapForConstellation:(NSString *)c;
+ (NSArray *) starsInConstellation:(NSString *)c;
+ (NSArray *) allStars;
+ (int) closestStarToPoint:(CGPoint)point;

+ (UIColor *) colorForStar:(int)n;
+ (UIColor *) circleColorForStar:(int)n;

// Star coordinates are authored in a fixed 1024 x 688 space. On screen they
// are mapped with separate horizontal and vertical scales (phones stretch the
// field sideways a little). pointForStar: and closestStarToPoint: use the
// mapped, on-screen coordinates of the star view.
+ (void) setFieldScaleX:(CGFloat)sx y:(CGFloat)sy;
+ (CGFloat) fieldScaleX;
+ (CGFloat) fieldScaleY;
+ (CGPoint) pointForStar:(int)n;

// Size multiplier for star dots, constellation lines and tap rings: follows
// the field scale but never drops below a clearly visible size.
+ (CGFloat) markScale;

// Highest and lowest star positions in the 1024 x 688 field (for spacing the
// field so the stars sit evenly between the screen's top and bottom edges).
+ (CGFloat) topmostStarY;
+ (CGFloat) bottommostStarY;


@end
