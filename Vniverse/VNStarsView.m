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
    
    NSMutableArray *highlightedStars;
    NSMutableArray *constellations;
    VNConstellationView *activeConstellation;
    
    NSString *canonConstellation;
    int currentTercet;
    NSTimer *tercetsTimer;
    BOOL didSuspendTercetsTimer;
    NSMutableArray<NSTimer *> *pendingTimers;   // one-shot Oracle effects, cancelled by clearScreen
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
        pendingTimers = [NSMutableArray array];
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
        
        CGPoint p = [VNData pointForStar:i];
        VNStar *star = [[VNStar alloc] initWithFrame:CGRectMake(0, 0, 12, 12) starID:i x:p.x y:p.y];
        [starObjs addObject:star];
        [self addSubview:star];
    }

    starObjects = [NSArray arrayWithArray:starObjs];
}

// Reposition and redraw stars and constellation lines after the field
// size or stretch changes.
- (void) refreshForDisplayScale {
    for (int i=1; i<[starObjects count]; i++) {
        VNStar *star = starObjects[i];
        star.center = [VNData pointForStar:i];
        [star setNeedsDisplay];
    }
    NSMutableArray *views = [NSMutableArray arrayWithArray:constellations];
    if (activeConstellation) [views addObject:activeConstellation];
    for (VNConstellationView *c in views) {
        c.frame = self.bounds;
        [c setNeedsDisplay];
    }
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
    [self scheduleOneShot:t target:self selector:@selector(showRandomStarWord)];
}

- (int) randomStarNumber {
    // Stars and tercets are numbered 1...232 (index 0 is a placeholder).
    return (int)arc4random_uniform((uint32_t)[VNData tercetCount] - 1) + 1;
}


- (void) scheduleOneShot:(NSTimeInterval)t target:(id)target selector:(SEL)selector {
    [pendingTimers filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSTimer *timer, NSDictionary *bindings) { return timer.isValid; }]];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:t target:target selector:selector userInfo:nil repeats:NO];
    [pendingTimers addObject:timer];
}

- (void) cancelPendingTimers {
    for (NSTimer *timer in pendingTimers) [timer invalidate];
    [pendingTimers removeAllObjects];
}



//////////
// TEXT //
//////////

- (void) startPlayingTercets:(int)tercet {

    [self clearAllConstellations];
    canonConstellation = [VNData constellationForStar:tercet];
    [self showCanonConstellationBehindTercet:canonConstellation];

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
    [self.textView showTercet:tercet];
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
    [self.textView showAllNumbers];
}

- (void) showRandomStarWord {
    [self.textView showWordForStar:[self randomStarNumber]];
}

- (void) showRandomStarWordInColor {
    [self.textView showWordInColorForStar:[self randomStarNumber]];
}

- (void) showRandomStarWordQuick {
    [self.textView showQuickWordForStar:[self randomStarNumber]];
}



//////////////////////
// GESTURE HANDLING //
//////////////////////

- (void) tapSkyWithMode:(appMode)mode point:(CGPoint)point {
    
    int starID = [VNData closestStarToPoint:point];

    if(mode == DRAW) {
        [self.textView showWordForStar:starID];
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
    activeConstellation = [[VNConstellationView alloc] initWithFrame:self.bounds];
    [self addSubview:activeConstellation];
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
    [self.textView showWordForStar:starID];
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
    [self cancelPendingTimers];
    [self.textView clearAllText];
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
    
    [self.textView showTwoTercets:a and:b];
    
}


- (void) showOracleAnswer {

    [self clearAllConstellations];
    [self.textView showTercet:[self randomStarNumber]];
    
    int n = ABI(3) + 2;
    for(int i=0; i<n; i++){
        CGFloat t = 3.0 + ABF(5.0);
        [self scheduleOneShot:t target:self selector:@selector(showRandomStarWord)];
    }

    [self scheduleOneShot:8.5 target:self.textView selector:@selector(clearTercet)];
}


- (void) showOracleHowToKnow {

    int n = ABI(3) + 6;
    for(int i=0; i<n; i++){
        CGFloat t = 0.5 + ABF(11.0);
        [self scheduleOneShot:t target:self selector:@selector(showRandomStarWordInColor)];
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
        color = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.5];
    }
    [self addGrowingCircleAtPoint:[VNData pointForStar:starID] withColor:color];
}


- (void) addGrowingCircleAtPoint:(CGPoint)point withColor:(UIColor *)color {
    
    // create a circle path
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGFloat comp = [VNData markScale];
    CGPathAddArc(circlePath, NULL, 0.f, 0.f, 7.f * comp, 0.f, (float)2.f*M_PI, true);
    
    // create a shape layer
    CAShapeLayer* layer = [[CAShapeLayer alloc] init];
    layer.path = circlePath;
    
    // don't leak, please!
    CGPathRelease(circlePath);
    
    // set up the attributes of the shape layer and add it to our view's layer
    layer.fillColor = [[UIColor clearColor] CGColor];
    layer.strokeColor = [color CGColor];
    layer.lineWidth = comp;
    layer.position = point;
    layer.anchorPoint = CGPointMake(.5f, .5f);

    // set up the growing animation
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"transform"];
    grow.fromValue = [layer valueForKey:@"transform"];
    CATransform3D t = CATransform3DMakeScale(7.f, 7.f, 1.f);
    grow.toValue = [NSValue valueWithCATransform3D:t];
    grow.duration = 1.f;
    grow.delegate = self;
    layer.transform = t;
    [grow setValue:layer forKey:@"layer"];
    [layer addAnimation:grow forKey:@"transform"];
    
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [layer valueForKey:@"opacity"];
    fade.toValue = [NSNumber numberWithFloat:0.f];
    fade.duration = .9f;
    fade.delegate = self;
    layer.opacity = 0.f;
    [fade setValue:@"fade" forKey:@"name"];
    [fade setValue:layer forKey:@"layer"];
    [layer addAnimation:fade forKey:@"opacity"];

    // Add to the tree last, so setting the final values above does not also
    // trigger implicit animations.
    [self.layer addSublayer:layer];
}


// when growing circle animation is complete, remove the layer
- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"name"] isEqual:@"fade"]) {
        CALayer* layer = [anim valueForKey:@"layer"];
        if(layer) [layer removeFromSuperlayer];
    }
}

@end


