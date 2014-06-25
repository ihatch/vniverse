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
+ (CGFloat) screenWidth;
+ (CGFloat) currentScreenWidth;
+ (CGRect) currentScreenBoundsForOrientation;


@end
