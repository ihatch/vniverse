//
//  VNData.m
//  Vniverse
//
//  Created by Ian Hatcher on 1/20/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNData.h"

//////////////////////////////
// GLOBAL UTILITY FUNCTIONS //
//////////////////////////////

CGFloat ABF(CGFloat multiplier) {
    return ((float)rand() / RAND_MAX) * multiplier;
}
int ABI(int max) {
    return (int) arc4random_uniform(max);
}


@implementation VNData

VNData *dataInstance;
NSArray *tercets;
NSArray *stars;
NSDictionary *constellations;
NSDictionary *constellationColors;
NSDictionary *constellationColorsForCircles;
NSDictionary *maps;
int cachedScreenWidth;


+ (void) initialize {
    @synchronized(self) {
        if (dataInstance == NULL) {
            dataInstance = [[self alloc] init];
            [VNData createConstellationColors];
            [VNData parseConstellationsFile];
            [VNData parseTercetsFile];
            [VNData parseStarsFile];
        }
    }
}

+ (void) createConstellationColors {

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[UIColor colorWithRed:0.9 green:0.0 blue:0.1 alpha:1] forKey:@"swimmer"];
    [dict setObject:[UIColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:1] forKey:@"conductor"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.4 blue:0.6 alpha:1] forKey:@"broom"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:1] forKey:@"dipper"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.9 blue:0.9 alpha:1] forKey:@"twins"];
    [dict setObject:[UIColor colorWithRed:0.2 green:0.6 blue:0.4 alpha:1] forKey:@"bull"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.7 blue:0.7 alpha:1] forKey:@"embryo"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:1] forKey:@"goose"];
    [dict setObject:[UIColor colorWithRed:0.8 green:0.6 blue:0.2 alpha:1] forKey:@"infinity"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.6 blue:0.2 alpha:1] forKey:@"dragonfly"];
    constellationColors = [NSDictionary dictionaryWithDictionary:dict];
    
    dict = [NSMutableDictionary dictionary];
    [dict setObject:[UIColor colorWithRed:0.9 green:0.0 blue:0.1 alpha:0.6] forKey:@"swimmer"];
    [dict setObject:[UIColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:0.6] forKey:@"conductor"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.4 blue:0.6 alpha:0.6] forKey:@"broom"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.6 blue:0.8 alpha:0.6] forKey:@"dipper"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.9 blue:0.9 alpha:0.6] forKey:@"twins"];
    [dict setObject:[UIColor colorWithRed:0.2 green:0.6 blue:0.4 alpha:0.6] forKey:@"bull"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.7 blue:0.7 alpha:0.6] forKey:@"embryo"];
    [dict setObject:[UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:0.6] forKey:@"goose"];
    [dict setObject:[UIColor colorWithRed:0.8 green:0.6 blue:0.2 alpha:0.6] forKey:@"infinity"];
    [dict setObject:[UIColor colorWithRed:0.0 green:0.6 blue:0.2 alpha:0.6] forKey:@"dragonfly"];
    constellationColorsForCircles = [NSDictionary dictionaryWithDictionary:dict];

}


+ (void) parseConstellationsFile {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v-constellations" ofType:@"txt"];
    NSString *rawConstel = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *rawConstels = [rawConstel componentsSeparatedByString:@"\n\n"];
    NSMutableDictionary *parsedConstels = [[NSMutableDictionary alloc] init];
    
    for (int i = 0; i < [rawConstels count]; i++) {
        NSMutableArray *map = [NSMutableArray arrayWithArray: [rawConstels[i] componentsSeparatedByString:@"\n"]];
        NSString *title = [map objectAtIndex:0];
        [map removeObjectAtIndex:0];
        [parsedConstels setObject:map forKey:title];
    }
    
    maps = [NSDictionary dictionaryWithDictionary:parsedConstels];
}



+ (void) parseTercetsFile {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v-tercets" ofType:@"txt"];
    NSString *rawText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    rawText = [rawText stringByReplacingOccurrencesOfString:@"--" withString:@"_"];
    rawText = [rawText stringByReplacingOccurrencesOfString:@"<i>" withString:@"^"];
    rawText = [rawText stringByReplacingOccurrencesOfString:@"</i>" withString:@"^"];
    
    NSArray *rawTercets = [rawText componentsSeparatedByString:@"\n\n"];
    NSMutableArray *parsedTercets = [NSMutableArray array];
    [parsedTercets addObject:@[]];
    
    for (int i = 0; i < [rawTercets count]; i++) {
        NSMutableArray *lines = [NSMutableArray arrayWithArray: [rawTercets[i] componentsSeparatedByString:@"\n"]];
        [lines removeObjectAtIndex:0];
        [parsedTercets addObject:[NSArray arrayWithArray:lines]];
    }
    
    tercets = [NSArray arrayWithArray:parsedTercets];
}


+ (void) parseStarsFile {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v-stars" ofType:@"txt"];
    NSString *rawText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *conArray = [rawText componentsSeparatedByString:@"\n\n"];

    path = [[NSBundle mainBundle] pathForResource:@"v-words" ofType:@"txt"];
    rawText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *wordsArray = [rawText componentsSeparatedByString:@"\n"];

    NSMutableDictionary *starData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *constelsToAdd = [[NSMutableDictionary alloc] init];
    
    for (int c = 0; c < [conArray count]; c++) {
        
        NSArray *starArray = [NSArray arrayWithArray: [conArray[c] componentsSeparatedByString:@"\n"]];
        NSString *constelName = [starArray objectAtIndex:0];
        NSMutableArray *starsInThisConstel = [[NSMutableArray alloc] init];

        for (int s = 1; s < [starArray count]; s++) {

            NSArray *star = [NSArray arrayWithArray:[[starArray objectAtIndex:s] componentsSeparatedByString:@" "]];
            NSNumber *starID = [star objectAtIndex:0];
            NSString *starWord = [wordsArray objectAtIndex:([starID intValue] - 1)];
            
            float x = ([[star objectAtIndex:1] floatValue] * 1.35) + 10;
            float y = ([[star objectAtIndex:2] floatValue] * 1.2) - 50;

            NSDictionary *coords = @{@"x" : @(x), @"y" : @(y), @"word" : starWord, @"constellation" : constelName };
            
            [starData setObject:coords forKey:starID];
            [starsInThisConstel addObject:starID];
        }

        [constelsToAdd setObject:[NSArray arrayWithArray:starsInThisConstel] forKey:constelName];
    }
    

    NSMutableArray *starsToAdd = [[NSMutableArray alloc] init];
    [starsToAdd addObject:@[]]; // Blank object for zero, since there is no star with ID:0

    for(int i=1; i < [starData count] + 1; i++){
        NSString *key = [NSString stringWithFormat:@"%i", i];
        [starsToAdd addObject:[starData objectForKey:key]];
    }
    
    stars = [NSArray arrayWithArray:starsToAdd];
    constellations = [NSDictionary dictionaryWithDictionary:constelsToAdd];
}


+ (int) closestStarToPoint:(CGPoint)point {
    
    int closestStarID = 0;
    int closestDistance = 99999;
    for(int i=1; i<[stars count]; i++){
        NSDictionary *star = stars[i];
        int starX = [[star objectForKey:@"x"] intValue];
        int starY = [[star objectForKey:@"y"] intValue];
        double dx = (starX - point.x);
        double dy = (starY - point.y);
        double dist = sqrt(dx*dx + dy*dy);
        if(dist < closestDistance ) {
            closestStarID = i;
            closestDistance = dist;
        }
    }
    
    return closestStarID;
}



+ (NSArray *) tercetAtIndex:(int)t {
    return tercets[t];
}

+ (int) tercetCount {
    return (int)[tercets count];
}


+ (CGPoint) coordinatesForStar:(int)n {
    int x = [[stars[n] objectForKey:@"x"] intValue];
    int y = [[stars[n] objectForKey:@"y"] intValue];
    CGPoint point = CGPointMake(x, y);
    return point;
}

+ (NSString *) wordForStar:(int)n {
    return [stars[n] objectForKey:@"word"];
}

+ (NSString *) constellationForStar:(int)n {
    return [stars[n] objectForKey:@"constellation"];
}

+ (NSArray *) mapForConstellation:(NSString *)c {
    return [maps objectForKey:c];
}

+ (NSArray *) starsInConstellation:(NSString *)c {
    return [constellations objectForKey:c];
}

+ (UIColor *) colorForStar:(int)n {
    return [VNData colorForConstellation:[VNData constellationForStar:n]];
}

+ (UIColor *) colorForConstellation:(NSString *)c {
    return [constellationColors objectForKey:c];
}

+ (UIColor *) circleColorForStar:(int)n {
    return [VNData circleColorForConstellation:[VNData constellationForStar:n]];
}

+ (UIColor *) circleColorForConstellation:(NSString *)c {
    return [constellationColorsForCircles objectForKey:c];
}

+ (NSArray *) allStars {
    return stars;
}






////////////
// SCREEN //
////////////

+ (CGFloat) screenWidth {
    if(!cachedScreenWidth) {
        cachedScreenWidth = [VNData currentScreenWidth];
    }
    return cachedScreenWidth;
}

+ (CGFloat) currentScreenWidth {
    CGRect rect = [VNData currentScreenBoundsForOrientation];
    return rect.size.width;
}

+ (CGRect) currentScreenBoundsForOrientation {
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        screenBounds.size = CGSizeMake(width, height);
    } else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        screenBounds.size = CGSizeMake(height, width);
    }
    
    return screenBounds;
}


@end
