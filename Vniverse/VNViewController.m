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
appMode currentMode;

VNViewController *thisController;
VNData *data;
VNStarsView *starsView;
VNWord *sliderValueDisplay;
VNBlackCurtain *curtain;

CGRect screenBounds, scrollBounds, inScrollBounds;
UIScrollView *scrollView;
UIView *topBarView, *textView, *constellationsModal, *oracleModal, *infoModal;
UIWebView *infoView;
UIButton *activeNavButton, *clearButton, *drawButton, *consButton, *waveButton, *oracleButton, *infoButton;
UIColor *normalColor, *selectedColor, *standardBackColor, *initBackColor;
NSArray *oracleQuestions;
int stardateDestination;

@implementation VNViewController

@synthesize backgroundTimer;

//////////
// INIT //
//////////

- (void)viewDidLoad {
    
    [super viewDidLoad];
    thisController = self;
    
    screenBounds = CGRectMake(0, 0, 1024, 768);
    scrollBounds = CGRectMake(0, 80, 1024, 688);
    inScrollBounds = CGRectMake(0, 0, 1024, 688);
    
    normalColor = [UIColor colorWithRed:0.65 green:0.75 blue:0.85 alpha:1];
    selectedColor = [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1];
    standardBackColor = [UIColor colorWithRed:0.25 green:0.13 blue:0.25 alpha:0.8];
    initBackColor = [UIColor colorWithRed:0.14 green:0.09 blue:0.15 alpha:0.90];
    

    oracleQuestions = @[@"Whose body?",
                        @"How to know?",
                        @"Why care?",
                        @"What do I love?",
                        @"Where to build a bridge?",
                        @"When did you say?",
                        @"Which one?"];

    self.view.backgroundColor = initBackColor;
    currentMode = DRAW;

    [self initScrollView];
    [self initStarsView];
    [self initTopBarView];
        
    self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:16.0 target:thisController selector:@selector(slowFadeBackground) userInfo:nil repeats:YES];
    [self slowFadeBackground];
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

+ (void) suspendTimers {
    [thisController.backgroundTimer invalidate];
    [starsView suspendTimers];
}

+ (void) resumeTimers {
    thisController.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:16.0 target:self selector:@selector(slowFadeBackground) userInfo:nil repeats:YES];
    [starsView resumeTimers];
}


- (void) initTopBarView {
    topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, 1024, 60)];
    topBarView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [self.view addSubview:topBarView];
    [self initTopButtons];
}


- (void) initScrollView {
    
    scrollView = [[UIScrollView alloc] initWithFrame:scrollBounds];
    scrollView.maximumZoomScale = 1.0f;
    scrollView.minimumZoomScale = 1.0f;
    scrollView.delegate = self;
    scrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    scrollView.bouncesZoom = NO;
    scrollView.bounces = NO;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondToLongPressGesture:)];
    longPress.minimumPressDuration = 0.005;
    [scrollView addGestureRecognizer:longPress];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(respondToTapGesture:)];
    [scrollView addGestureRecognizer:tap];

    [self.view addSubview:scrollView];
}


- (void) initStarsView {
    starsView = [[VNStarsView alloc] initWithFrame:inScrollBounds];
    [scrollView addSubview:starsView];
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
    [button setTitleEdgeInsets:UIEdgeInsetsZero];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back.png"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back_bright.png"] forState:UIControlStateHighlighted];
    [button setBackgroundImage:[UIImage imageNamed:@"button_back_bright.png"] forState:UIControlStateSelected];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor:normalColor.CGColor];
    [button.layer setCornerRadius:8.0f];
    return button;
}



- (void) initTopButtons {
    
    int y = 10, h = 40, w = 0, x = 20, smallGap = 10, bigGap = 400;
    int wClear = 70, wDraw = 70, wCons = 135, wWave = 125, wOracle = 80, wInfo = 65;
    
    w = wDraw;
    drawButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Draw" tag:MODE];
    [topBarView addSubview:drawButton];
    [drawButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    drawButton.selected = YES;
    activeNavButton = drawButton;
    x += w + smallGap;
    
    w = wCons;
    consButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Constellations" tag:MODE];
    [consButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:consButton];
    x += w + smallGap;
    
    w = wWave;
    waveButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"WaveTercets" tag:MODE];
    [waveButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:waveButton];
    x += w + smallGap;
    
    w = wOracle;
    oracleButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Oracle" tag:MODE];
    [oracleButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:oracleButton];
    x += w + bigGap;
    
    w = wClear;
    clearButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Clear" tag:MODE];
    [clearButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:clearButton];
    x += w + smallGap;
    
    w = wInfo;
    infoButton = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Info" tag:MODE];
    [infoButton addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:infoButton];
}



- (void) switchToDrawMode {
    currentMode = DRAW;
    if(activeNavButton) activeNavButton.selected = NO;
    activeNavButton = drawButton;
    drawButton.selected = YES;
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
            curtain = [[VNBlackCurtain alloc] init];
            [self.view addSubview:curtain];
            [curtain addSubview:[self constellationsModal]];
            [curtain show];
        }
        
        if([bt isEqualToString:@"WaveTercets"]) {
            changeSelectedNavButton = YES;
            [starsView clearScreen];
            currentMode = WAVETERCETS;
            [starsView startPlayingTercets:1];
        }
        
        if([bt isEqualToString:@"Oracle"]) {
            curtain = [[VNBlackCurtain alloc] init];
            [self.view addSubview:curtain];
            [curtain addSubview:[self oracleModal]];
            [curtain show];
        }
        
        if([bt isEqualToString:@"Clear"]) {
            [starsView clearScreen];
            [self switchToDrawMode];
        }
        
        if([bt isEqualToString:@"Info"]) {
            curtain = [[VNBlackCurtain alloc] init];
            [self.view addSubview:curtain];
            [curtain addSubview:[self infoModal]];
            [curtain show];
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
            curtain = [[VNBlackCurtain alloc] init];
            [self.view addSubview:curtain];
            [curtain addSubview:[self stardateModal]];
            [curtain show];
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

    CGFloat mw = w, mh = h, mx = ((1024 - mw) / 2), my = ((768 - mh) / 2);
    UIView *modal = [[UIView alloc] initWithFrame:CGRectMake(mx, my, mw, mh)];

    [modal.layer setBorderWidth:1.0f];
    [modal.layer setBorderColor:normalColor.CGColor];
    modal.userInteractionEnabled = YES;
    modal.backgroundColor = standardBackColor;

    return modal;
}

- (UIView *) infoModal {
    
    UIView *modal = [self createModalWithWidth:910 andHeight:660];

    infoView = [[UIWebView alloc] initWithFrame:CGRectMake(30, 20, 850, 610)];
    
    NSString *infoPath = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html"];
    if (infoPath) {
        NSData *htmlData = [NSData dataWithContentsOfFile:infoPath];
        [infoView loadData:htmlData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:[[NSBundle mainBundle] bundleURL]];
    }
    infoView.scrollView.scrollEnabled = NO;
    infoView.scrollView.bounces = NO;
    [infoView setBackgroundColor:[UIColor clearColor]];
    [infoView setOpaque: NO];
    
    infoView.delegate = self;
    
    [modal addSubview:infoView];

    int x = 760, y = 590, w = 110, h = 40;
    UIButton *b = [self createButtonWithFrame:CGRectMake(x, y, w, h) title:@"Close" tag:CLOSE];
    [modal addSubview:b];
    [b addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    
    return modal;
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
        [b addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
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
        [b addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
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
    [b addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
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

- (IBAction) respondToTapGesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:starsView];
    [starsView tapSkyWithMode:currentMode point:point];
}


- (IBAction) respondToLongPressGesture:(UILongPressGestureRecognizer *)gesture {
    if(currentMode == DRAW) {
        if(gesture.state == UIGestureRecognizerStateBegan) {
            [starsView startDrawingConstellation];
            CGPoint point = [gesture locationInView:starsView];
            [starsView moveFingerWhileDrawingConstellation:point];
        } else if(gesture.state == UIGestureRecognizerStateEnded) {
            // nothin
        } else if(gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint point = [gesture locationInView:starsView];
            [starsView moveFingerWhileDrawingConstellation:point];
        }
    } else {
        CGPoint point = [gesture locationInView:starsView];
        [starsView tapSkyWithMode:currentMode point:point];
    }
}


- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return starsView;
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

@end
