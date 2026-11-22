//
//  VNViewController.m
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNViewController.h"
#import "VNData.h"
#import "VNStar.h"
#import "VNStarsView.h"
#import "VNTercet.h"
#import "VNWord.h"
#import "VNBlackCurtain.h"

typedef enum { MODE, CONSTELLATION, ORACLEQUESTION, STARDATE, CLOSE } buttonType;

// The star field is authored in a fixed 1024 x 688 coordinate space (the sky
// area of the original iPad screen). It is scaled to fit whatever space the
// current device or window offers, so every star keeps its relative position.
static const CGFloat kSkyWidth = 1024;
static const CGFloat kSkyHeight = 688;
static const CGFloat kTopBarHeight = 60;

static appMode currentMode;

static VNViewController *thisController;
static VNStarsView *starsView;
static VNWord *sliderValueDisplay;
static VNBlackCurtain *curtain;

static UIView *skyView, *topBarView;
static WKWebView *infoView;

static UIButton *activeNavButton, *clearButton, *drawButton, *consButton, *waveButton, *oracleButton, *infoButton;
static UIColor *normalColor, *selectedColor, *standardBackColor, *initBackColor;
static int stardateDestination;

@implementation VNViewController

@synthesize backgroundTimer;

//////////
// INIT //
//////////

- (void)viewDidLoad {
    
    [super viewDidLoad];
    thisController = self;
    
    normalColor = [UIColor colorWithRed:0.65 green:0.75 blue:0.85 alpha:1];
    selectedColor = [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1];
    standardBackColor = [UIColor colorWithRed:0.25 green:0.13 blue:0.25 alpha:0.8];
    initBackColor = [UIColor colorWithRed:0.14 green:0.09 blue:0.15 alpha:0.90];

    self.view.backgroundColor = initBackColor;
    currentMode = DRAW;

    [self initSkyView];
    [self initStarsView];
    [self initTopBarView];

    [self startBackgroundTimer];
    [self slowFadeBackground];
}


- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (BOOL) prefersHomeIndicatorAutoHidden {
    return YES;
}


// Lay everything out against the real view size and safe area, instead of
// assuming a 1024 x 768 screen with a 20pt status bar.
- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;

    topBarView.frame = CGRectMake(0, safe.top, bounds.size.width, kTopBarHeight);
    [self layoutTopButtons];

    CGFloat skyTop = CGRectGetMaxY(topBarView.frame);
    skyView.frame = CGRectMake(0, skyTop, bounds.size.width, bounds.size.height - skyTop - safe.bottom);

    CGFloat scale = MIN(skyView.bounds.size.width / kSkyWidth, skyView.bounds.size.height / kSkyHeight);
    if (scale <= 0) scale = 1;
    starsView.transform = CGAffineTransformMakeScale(scale, scale);
    starsView.center = CGPointMake(CGRectGetMidX(skyView.bounds), CGRectGetMidY(skyView.bounds));
}


- (void) slowFadeBackground {
    [VNViewController slowFadeBackground];
}


+ (void) slowFadeBackground {
    CGFloat r = 0.12 + (ABF(0.06));
    CGFloat g = 0.04 + (ABF(0.06));
    CGFloat b = 0.14 + (ABF(0.06));
    
    [UIView animateWithDuration:15.9 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        thisController.view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.90];
    } completion:^(BOOL finished) {}];
}

- (void) startBackgroundTimer {
    [self.backgroundTimer invalidate];
    self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:16.0 target:self selector:@selector(slowFadeBackground) userInfo:nil repeats:YES];
}

+ (void) suspendTimers {
    [thisController.backgroundTimer invalidate];
    thisController.backgroundTimer = nil;
    [starsView suspendTimers];
}

+ (void) resumeTimers {
    // Also runs once at launch, so restart rather than add a second timer.
    [thisController startBackgroundTimer];
    [starsView resumeTimers];
}


- (void) initTopBarView {
    topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kSkyWidth, kTopBarHeight)];
    topBarView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [self.view addSubview:topBarView];
    [self initTopButtons];
}


// Plain container for the sky. (This used to be a UIScrollView, but with
// zoom locked at 1.0 and no content size it never scrolled or zoomed.)
- (void) initSkyView {
    
    skyView = [[UIView alloc] initWithFrame:CGRectMake(0, kTopBarHeight, kSkyWidth, kSkyHeight)];
    skyView.clipsToBounds = NO;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondToLongPressGesture:)];
    longPress.minimumPressDuration = 0.005;
    [skyView addGestureRecognizer:longPress];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondToTapGesture:)];
    [skyView addGestureRecognizer:tap];

    [self.view addSubview:skyView];
}


- (void) initStarsView {
    starsView = [[VNStarsView alloc] initWithFrame:CGRectMake(0, 0, kSkyWidth, kSkyHeight)];
    [skyView addSubview:starsView];
    [starsView initStars];
}



/////////////
// BUTTONS //
/////////////

- (UIButton *) createButtonWithFrame:(CGRect)frame title:(NSString *)title tag:(buttonType)tag {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont fontWithName:@"EuphemiaUCAS" size:14];

    [button setTag:tag];
    [button setFrame:frame];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:normalColor forState:UIControlStateNormal];
    [button setTitleColor:selectedColor forState:UIControlStateSelected];
    [button setTitleColor:selectedColor forState:UIControlStateHighlighted];
    [button setClipsToBounds:YES];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back_bright.png"] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back_bright.png"] forState:UIControlStateSelected];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor:normalColor.CGColor];
    [button.layer setCornerRadius:8.0f];
    [button addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}



- (void) initTopButtons {
    
    int y = 10, h = 40;
    
    drawButton   = [self createButtonWithFrame:CGRectMake(0, y, 70, h)  title:@"Draw" tag:MODE];
    consButton   = [self createButtonWithFrame:CGRectMake(0, y, 135, h) title:@"Constellations" tag:MODE];
    waveButton   = [self createButtonWithFrame:CGRectMake(0, y, 125, h) title:@"WaveTercets" tag:MODE];
    oracleButton = [self createButtonWithFrame:CGRectMake(0, y, 80, h)  title:@"Oracle" tag:MODE];
    clearButton  = [self createButtonWithFrame:CGRectMake(0, y, 70, h)  title:@"Clear" tag:MODE];
    infoButton   = [self createButtonWithFrame:CGRectMake(0, y, 65, h)  title:@"Info" tag:MODE];

    for (UIButton *b in @[drawButton, consButton, waveButton, oracleButton, clearButton, infoButton]) {
        [topBarView addSubview:b];
    }
    
    drawButton.selected = YES;
    activeNavButton = drawButton;
    [self layoutTopButtons];
}


// Mode buttons sit on the left, Clear and Info on the right edge.
- (void) layoutTopButtons {
    CGFloat margin = 20, gap = 10;
    
    CGFloat x = margin;
    for (UIButton *b in @[drawButton, consButton, waveButton, oracleButton]) {
        CGRect f = b.frame; f.origin.x = x; b.frame = f;
        x += f.size.width + gap;
    }
    
    x = topBarView.bounds.size.width - margin;
    for (UIButton *b in @[infoButton, clearButton]) {
        CGRect f = b.frame; x -= f.size.width; f.origin.x = x; b.frame = f;
        x -= gap;
    }
}



- (void) switchToDrawMode {
    currentMode = DRAW;
    if(activeNavButton) activeNavButton.selected = NO;
    activeNavButton = drawButton;
    drawButton.selected = YES;
}


- (void) presentModal:(UIView *)modal {
    curtain = [[VNBlackCurtain alloc] initWithFrame:self.view.bounds];
    curtain.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:curtain];
    modal.center = CGPointMake(CGRectGetMidX(curtain.bounds), CGRectGetMidY(curtain.bounds));
    modal.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                             UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [curtain addSubview:modal];
    [curtain show];
}


- (void) buttonPress:(UIButton *)button {
    
    NSString *bt = [button currentTitle];
    
    if(button.tag == MODE) {
        
        BOOL changeSelectedNavButton = NO;
        
        if([bt isEqualToString:@"Draw"]) {
            changeSelectedNavButton = YES;
            [starsView clearScreen];
            currentMode = DRAW;
        }
        
        if([bt isEqualToString:@"Constellations"]) {
            [self presentModal:[self constellationsModal]];
        }
        
        if([bt isEqualToString:@"WaveTercets"]) {
            changeSelectedNavButton = YES;
            [starsView clearScreen];
            currentMode = WAVETERCETS;
            [starsView startPlayingTercets:1];
        }
        
        if([bt isEqualToString:@"Oracle"]) {
            [self presentModal:[self oracleModal]];
        }
        
        if([bt isEqualToString:@"Clear"]) {
            [starsView clearScreen];
            [self switchToDrawMode];
        }
        
        if([bt isEqualToString:@"Info"]) {
            [self presentModal:[self infoModal]];
        }
        
        if(changeSelectedNavButton) {
            if(activeNavButton) activeNavButton.selected = NO;
            activeNavButton = button;
            button.selected = YES;
        }
        
    }
    
    
    if(button.tag == CLOSE) {
        [curtain hide];
    }
    
    
    if(button.tag == CONSTELLATION) {
        [curtain hide];

        if(activeNavButton) activeNavButton.selected = NO;
        activeNavButton = consButton;
        consButton.selected = YES;
        
        [starsView clearScreen];
        currentMode = CONSTELLATIONS;
        
        NSString *c = button.titleLabel.text;
        [starsView showCanonConstellation:c];
    }
    
    
    if(button.tag == ORACLEQUESTION) {
        [curtain hide];
        
        if([bt isEqualToString:@"Whose body?"]) {
            [starsView clearScreen];
            [starsView showOracleAnswer];
            [self switchToDrawMode];
        }
        
        if([bt isEqualToString:@"How to know?"]) {
            [starsView clearScreen];
            [starsView showOracleHowToKnow];
            [self switchToDrawMode];
        }

        if([bt isEqualToString:@"Why care?"]) {
            [starsView clearScreen];
            [starsView hideStars];
            [self switchToDrawMode];
        }

        if([bt isEqualToString:@"What do I love?"]) {
            [starsView clearScreen];
            [starsView showOracleAnswer];
            [self switchToDrawMode];
        }
        
        if([bt isEqualToString:@"Where to build a bridge?"]) {
            [starsView clearScreen];
            [starsView showBridge];
            [self switchToDrawMode];
        }
        
        if([bt isEqualToString:@"When did you say?"]) {
            [self presentModal:[self stardateModal]];
        }
        
        if([bt isEqualToString:@"Which one?"]) {
            [starsView clearScreen];
            [starsView showAllNumbers];
            [self switchToDrawMode];
        }

    }
    
    if(button.tag == STARDATE) {
        [curtain hide];
        [starsView clearScreen];
        
        if(activeNavButton) activeNavButton.selected = NO;
        activeNavButton = waveButton;
        waveButton.selected = YES;
        currentMode = WAVETERCETS;
        
        [starsView startPlayingTercets:stardateDestination];
    }
}




////////////
// MODALS //
////////////


- (UIView *) createModalWithWidth:(CGFloat)w andHeight:(CGFloat)h {

    UIView *modal = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];

    [modal.layer setBorderWidth:1.0f];
    [modal.layer setBorderColor:normalColor.CGColor];
    modal.userInteractionEnabled = YES;
    modal.backgroundColor = standardBackColor;

    return modal;
}

- (UIView *) infoModal {
    
    UIView *modal = [self createModalWithWidth:910 andHeight:660];
    
    infoView = [[WKWebView alloc] initWithFrame:CGRectMake(30, 20, 850, 610)];
    infoView.navigationDelegate = self;

    NSString *infoPath = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
    if (infoPath) {
        NSURL *fileURL = [NSURL fileURLWithPath:infoPath];
        [infoView loadFileURL:fileURL allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
    }

    infoView.scrollView.scrollEnabled = NO;
    infoView.scrollView.bounces = NO;
    infoView.backgroundColor = [UIColor clearColor];
    infoView.opaque = NO;

    [modal addSubview:infoView];
    UIButton *b = [self createButtonWithFrame:CGRectMake(760, 590, 110, 40) title:@"Close" tag:CLOSE];
    [modal addSubview:b];
    
    return modal;
}


// Open links from the Info page in Safari rather than inside the small,
// non-scrolling info box.
- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && url && !url.isFileURL) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (UIView *) constellationsModal {
    
    UIView *modal = [self createModalWithWidth:290 andHeight:280];

    int x = 20, y = 20, w = 120, h = 40;
    NSArray *cs = @[@"swimmer", @"conductor", @"broom", @"dipper", @"twins",
                    @"bull", @"embryo", @"goose", @"infinity", @"dragonfly"];
    
    for(int i=0; i<[cs count]; i++){
        if(i == 5) y = 20;
        if(i > 4) x = 150;
        UIButton *b = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:cs[i] tag:CONSTELLATION];
        [modal addSubview:b];
        y += 50;
    }
    
    return modal;
}


- (UIView *) oracleModal {

    UIView *modal = [self createModalWithWidth:290 andHeight:380];
    
    int x = 20, y = 20, w = 250, h = 40;
    
    NSArray *cs = @[@"Whose body?",
                    @"How to know?",
                    @"Why care?",
                    @"What do I love?",
                    @"Where to build a bridge?",
                    @"When did you say?",
                    @"Which one?"];
    
    for(int i=0; i<[cs count]; i++){
        UIButton *b = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:cs[i] tag:ORACLEQUESTION];
        [modal addSubview:b];
        y += 50;
    }
    
    return modal;
}


- (UIView *) stardateModal {
    
    UIView *modal = [self createModalWithWidth:290 andHeight:180];

    stardateDestination = 1;
    sliderValueDisplay = [[VNWord alloc] initWithFrame:CGRectMake(20, 70, 250, 20) string:@"1" starID:0 size:17 colorize:NO];
    
    [modal addSubview:sliderValueDisplay];
    
    CGRect frame = CGRectMake(20, 30, 250.0, 30.0);
    UISlider *slider = [[UISlider alloc] initWithFrame:frame];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [slider setBackgroundColor:[UIColor clearColor]];
    slider.minimumValue = 1;
    slider.maximumValue = 232;
    slider.continuous = YES;
    slider.value = 1.0;
    
    [modal addSubview:slider];

    UIButton *b = [self createButtonWithFrame:CGRectMake(20, 120, 250, 40) title:@"teleport" tag:STARDATE];
    [modal addSubview:b];

    return modal;
}


- (void) sliderAction:(UISlider *)slider {
    int value = (int)(slider.value);
    [slider setValue:value animated:NO];
    [sliderValueDisplay setText:[NSString stringWithFormat:@"%d", value]];
    stardateDestination = value;
}




//////////////
// GESTURES //
//////////////

- (void) respondToTapGesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:starsView];
    [starsView tapSkyWithMode:currentMode point:point];
}


- (void) respondToLongPressGesture:(UILongPressGestureRecognizer *)gesture {
    if(currentMode == DRAW) {
        if(gesture.state == UIGestureRecognizerStateBegan) {
            [starsView startDrawingConstellation];
            CGPoint point = [gesture locationInView:starsView];
            [starsView moveFingerWhileDrawingConstellation:point];
        } else if(gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint point = [gesture locationInView:starsView];
            [starsView moveFingerWhileDrawingConstellation:point];
        }
    } else {
        CGPoint point = [gesture locationInView:starsView];
        [starsView tapSkyWithMode:currentMode point:point];
    }
}

@end
