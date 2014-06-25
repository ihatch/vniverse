//
//  DrawStarLineView.m
//  Vniverse
//

#import "VNStarsView.h"
#import "VNTextView.h"
#import "VNConstellationView.h"
#import "VNTercet.h"
#import "VNStar.h"
#import "VNData.h"
#import "VNWord.h"

@implementation VNStarsView {
    
    NSValue *drawingFingerPoint;
    NSArray *starObjects;

    int lastPathStarID;
    VNWord *currentStarNumber;
    VNTercet *activeTercet;
    VNTextView *textView;
    
    NSMutableArray *highlightedStars;
    NSMutableArray *constellations;
    VNConstellationView *activeConstellation;
    
    NSString *canonConstellation;
    int currentTercet;
    NSTimer *tercetsTimer;
    BOOL didSuspendTercetsTimer;
}



//////////
// INIT //
//////////

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        constellations = [NSMutableArray array];
        highlightedStars = [NSMutableArray array];

        textView = [[VNTextView alloc] initWithFrame:self.frame];
        [self addSubview:textView];
    }
    return self;
}



///////////
// STARS //
///////////

- (void) initStars {
    
    NSArray *stars = [VNData allStars];
    NSMutableArray *starObjs = [[NSMutableArray alloc] init];

    [starObjs addObject:@[]];
    
    for(int i=1; i<[stars count]; i++){
        
        NSDictionary *s = [stars objectAtIndex:i];
        int starX = [[s objectForKey:@"x"] intValue];
        int starY = [[s objectForKey:@"y"] intValue];
        
        VNStar *star = [[VNStar alloc] initWithFrame:CGRectMake(starX, starY, 12, 12) starID:i x:starX y:starY];
        [starObjs addObject:star];
        [self addSubview:star];
    }

    starObjects = [NSArray arrayWithArray:starObjs];
}

- (void) highlightStar:(VNStar *)star {
    [star addHighlight];
    [highlightedStars addObject:star];
}

- (void) clearStarHighlights {
    for(int i=0; i<[highlightedStars count]; i++){
        [highlightedStars[i] removeHighlight];
    }
    highlightedStars = [NSMutableArray array];
}

- (void) hideStars {
    for(int i=1; i<[starObjects count]; i++){
        [starObjects[i] hideStar];
    }

    CGFloat t = 4.0 + ABF(2.0);
    [NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(showRandomStarWord) userInfo:nil repeats:NO];

}

- (int) randomStarNumber {
    return (arc4random() % 231) + 1;
}



//////////
// TEXT //
//////////

- (void) startPlayingTercets:(int)tercet {

    [self clearAllConstellations];
    canonConstellation = [VNData constellationForStar:tercet];
    [self showCanonConstellationBehindTercet:canonConstellation];

    [self bringSubviewToFront:textView];
    currentTercet = tercet;
    [self showTercet:tercet];
    [self startTercetsTimer];
}


- (void) nextTercet {
    currentTercet ++;
    if(currentTercet > [VNData tercetCount] - 1) currentTercet = 1;

    NSString *constel = [VNData constellationForStar:currentTercet];
    if(![constel isEqualToString:canonConstellation]) {
        [self clearAllConstellations];
        canonConstellation = constel;
        [self showCanonConstellationBehindTercet:canonConstellation];
    }
    
    [self showTercet:currentTercet];
}


- (void) showTercet:(int)tercet {
    [textView showTercet:tercet];
    [self addGrowingCircleForStar:tercet withConstellationColor:YES];
}


- (void) startTercetsTimer {
    [self stopTercetsTimer];
    tercetsTimer = [NSTimer scheduledTimerWithTimeInterval:7.5 target:self selector:@selector(nextTercet) userInfo:nil repeats:YES];
}

- (void) stopTercetsTimer {
    if(tercetsTimer) {
        [tercetsTimer invalidate];
        tercetsTimer = nil;
    }
    
}

- (void) suspendTimers {
    if(tercetsTimer) {
        [tercetsTimer invalidate];
        tercetsTimer = nil;
        didSuspendTercetsTimer = YES;
    }
}

- (void) resumeTimers {
    if(didSuspendTercetsTimer) {
        [self startTercetsTimer];
        didSuspendTercetsTimer = NO;
    }
}

- (void) showAllNumbers {
    [self clearScreen];
    [textView showAllNumbers];
}

- (void) showRandomStarWord {
    [textView showWordForStar:[self randomStarNumber]];
}

- (void) showRandomStarWordInColor {
    [textView showWordInColorForStar:[self randomStarNumber]];
}

- (void) showRandomStarWordQuick {
    [textView showQuickWordForStar:[self randomStarNumber]];
}



//////////////////////
// GESTURE HANDLING //
//////////////////////

- (void) tapSkyWithMode:(appMode)mode point:(CGPoint)point {
    
    int starID = [VNData closestStarToPoint:point];

    if(mode == DRAW) {
        [textView showWordForStar:starID];
        [self addGrowingCircleForStar:starID withConstellationColor:NO];
    }

    if(mode == WAVETERCETS) {
        if(starID == currentTercet) return;
        currentTercet = starID;
        [self showTercet:starID];
        [self startTercetsTimer];
    }

    if(mode == CONSTELLATIONS) {
        if(starID == currentTercet) return;
        currentTercet = starID;
        [self showTercet:starID];
    }
}



//////////////////
// LINE DRAWING //
//////////////////

- (void) startDrawingConstellation {
    if(activeConstellation) [constellations addObject:activeConstellation];
    activeConstellation = [[VNConstellationView alloc] initWithFrame:self.frame];
    [self addSubview:activeConstellation];
    [self setNeedsDisplay];
    lastPathStarID = 0;
}

- (void) registerStarInConstellation:(int)starID {
    lastPathStarID = starID;
    VNStar *star = starObjects[starID];
    [self highlightStar:star];
    [activeConstellation addStarView:star];
    [activeConstellation setNeedsDisplay];
    
}

- (void) moveFingerWhileDrawingConstellation:(CGPoint)point {
    
    drawingFingerPoint = [NSValue valueWithCGPoint:point];
    if(activeConstellation) activeConstellation.drawingFingerPoint = drawingFingerPoint;

    int starID = [VNData closestStarToPoint:point];
    if(starID == lastPathStarID) return;

    [self addGrowingCircleForStar:starID withConstellationColor:NO];
    [textView showWordForStar:starID];
    [self registerStarInConstellation:starID];
}

- (void) clearAllConstellations {
    
    if(activeConstellation) {
        VNConstellationView *a = activeConstellation;
        [constellations addObject:a];
    }
    
    for(int i=0; i<[constellations count]; i++){
        VNConstellationView *c = [constellations objectAtIndex:i];
        [c deactivate];
    }
    
    [constellations removeAllObjects];
    activeConstellation = nil;
    [self setNeedsDisplay];
}



- (void) clearScreen {
    
    [self clearAllConstellations];
    [self clearStarHighlights];
    [self stopTercetsTimer];
    [textView clearAllText];
    [self setNeedsDisplay];
    currentTercet = 0;
}


- (void) showCanonConstellation:(NSString *)name {
    
    canonConstellation = name;
    [self startDrawingConstellation];
    NSArray *map = [VNData mapForConstellation:name];

    for(int i=0; i<[map count]; i++){
        if([[map objectAtIndex:i] isEqualToString:@"-"]){
            [self startDrawingConstellation];
            continue;
        }
        int s = [[map objectAtIndex:i] intValue];
        [self registerStarInConstellation:s];
    }
}


- (void) showCanonConstellationBehindTercet:(NSString *)name {
    
    canonConstellation = name;
    [self startDrawingConstellation];
    NSArray *map = [VNData mapForConstellation:name];
    
    for(int i=0; i<[map count]; i++){
        if([[map objectAtIndex:i] isEqualToString:@"-"]){
            [self startDrawingConstellation];
            continue;
        }
        int s = [[map objectAtIndex:i] intValue];
        [self registerStarInConstellation:s];
    }
}


- (void) showBridge {
    
    int a = [self randomStarNumber];
    int b = 0;
    while(b == 0 || b == a){
        b = [self randomStarNumber];
    }

    [self startDrawingConstellation];
    [self registerStarInConstellation:a];
    [self registerStarInConstellation:b];
    
    [textView showTwoTercets:a and:b];
    
}


- (void) showOracleAnswer {

    [self clearAllConstellations];
    [textView showTercet:[self randomStarNumber]];
    
    int n = ABI(3) + 2;
    for(int i=0; i<n; i++){
        CGFloat t = 3.0 + ABF(5.0);
        [NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(showRandomStarWord) userInfo:nil repeats:NO];
    }

    [NSTimer scheduledTimerWithTimeInterval:8.5 target:textView selector:@selector(clearTercet) userInfo:nil repeats:NO];
}


- (void) showOracleHowToKnow {

    int n = ABI(3) + 6;
    for(int i=0; i<n; i++){
        CGFloat t = 0.5 + ABF(11.0);
        [NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(showRandomStarWordInColor) userInfo:nil repeats:NO];
    }
    
}




/////////////////////////
// CIRCULAR HIGHLIGHTS //
/////////////////////////

- (void) addGrowingCircleForStar:(int)starID withConstellationColor:(BOOL)withConstellationColor {
    UIColor *color;
    if(withConstellationColor) {
        color = [VNData circleColorForStar:starID];
    } else {
        color = [UIColor colorWithRed:0.2 green:0.2 blue:0.7 alpha:0.6];
    }
    [self addGrowingCircleAtPoint:[VNData coordinatesForStar:starID] withColor:color];
}


- (void) addGrowingCircleAtPoint:(CGPoint)point withColor:(UIColor *)color {
    
    // create a circle path
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGPathAddArc(circlePath, NULL, 0.f, 0.f, 7.f, 0.f, (float)2.f*M_PI, true);
    
    // create a shape layer
    CAShapeLayer* layer = [[CAShapeLayer alloc] init];
    layer.path = circlePath;
    
    // don't leak, please!
    CGPathRelease(circlePath);
    layer.delegate = self;
    
    // set up the attributes of the shape layer and add it to our view's layer
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.strokeColor = [color CGColor];
    layer.position = point;
    layer.anchorPoint = CGPointMake(.5f, .5f);
    [self.layer addSublayer:layer];
    
    // set up the growing animation
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform"];
    grow.fromValue = [layer valueForKey:@"transform"];
    CATransform3D t = CATransform3DMakeScale(10.f, 10.f, 1.f);
    grow.toValue = [NSValue valueWithCATransform3D:t];
    grow.duration = 1.f;
    grow.delegate = self;
    layer.transform = t;
    [grow setValue:layer forKey:@"layer"];
    [layer addAnimation:grow forKey:@"transform"];
    
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [layer valueForKey:@"opacity"];
    fade.toValue = [NSNumber numberWithFloat:0.f];
    fade.duration = .7f;
    fade.delegate = self;
    layer.opacity = 0.f;
    [fade setValue:@"fade" forKey:@"name"];
    [fade setValue:layer forKey:@"layer"];
    [layer addAnimation:fade forKey:@"opacity"];
}


// when growing circle animation is complete, remove the layer
- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag && [[anim valueForKey:@"name"] isEqual:@"fade"]) {
        CALayer* layer = [anim valueForKey:@"layer"];
        if(layer) [layer removeFromSuperlayer];
    }
}

@end


