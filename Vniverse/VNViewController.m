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
#import "VNTextView.h"
#import "VNInfoView.h"

typedef enum { MODE, CONSTELLATION, ORACLEQUESTION, STARDATE, CLOSE } buttonType;

// The star field is authored in a fixed 1024 x 688 coordinate space (the sky
// area of the original iPad screen). It is scaled to fit whatever space the
// current device or window offers, so every star keeps its relative position.
static const CGFloat kSkyWidth = 1024;
static const CGFloat kSkyHeight = 688;
static const CGFloat kTopBarHeight = 60;

// On short screens (iPhones in landscape) the buttons live in a menu panel that
// slides out from the left when the corner menu button is tapped.
static const CGFloat kMenuItemWidth = 112;
static const CGFloat kMenuItemHeight = 32;
static const CGFloat kMenuItemGap = 12;
static const CGFloat kMenuItemFontSize = 13;
static const CGFloat kMenuButtonSize = 32;   // square, same height as the menu items (kMenuItemHeight)
static const CGFloat kMenuLineSpacing = 5;
static const CGFloat kMenuButtonInset = 16;          // screens with square corners (e.g. iPhone SE)
static const CGFloat kRoundedCornerInset = 24;      // screens with rounded corners: clear of the curve
static const NSTimeInterval kMenuDuration = 0.42;

// Text never shrinks below this fraction of its iPad size, however small the
// star field gets.
static const CGFloat kMinTextScale = 0.8;

// How much the star field may be stretched along its longer spare axis (about
// what phones get from the "half the leftover space" rule).
static const CGFloat kMaxStretch = 0.23;
// iPad in portrait gets 50% more vertical stretch, and darker fades above and
// below the field.
static const CGFloat kMaxPortraitStretch = 0.345;
static const CGFloat kFadeAlpha = 0.2, kPortraitFadeAlpha = 0.35;

// Narrowest window that still fits the top bar of buttons.
static const CGFloat kMinTopBarWidth = 680;

static appMode currentMode;

static VNViewController *thisController;
static VNStarsView *starsView;
static VNTextView *textLayer;
static VNWord *sliderValueDisplay;
static VNBlackCurtain *curtain;

static UIView *skyView, *barView;
static UIView *infoModalView;

static BOOL phoneLayout, menuOpen;
static UIView *leftMargin, *rightMargin, *topFade, *bottomFade, *menuDimView;
static UIButton *menuButton;
static NSArray<UIView *> *menuLines;
static UIViewPropertyAnimator *menuAnimator;
static UIColor *menuBackColor;

static NSArray<UIButton *> *modeButtons, *utilityButtons;
static NSArray<NSNumber *> *modeButtonWidths, *utilityButtonWidths;   // widths in the top bar
static UIButton *activeNavButton, *clearButton, *drawButton, *consButton, *waveButton, *oracleButton, *infoButton;
static UIColor *borderColor;   // light-blue outlines, softened to 65% of normalColor
static UIColor *normalColor, *selectedColor, *standardBackColor;
static int stardateDestination;

// A view backed by a gradient layer, so the gradient follows the view's frame.
@interface VNGradientView : UIView
@end

@implementation VNGradientView
+ (Class) layerClass {
    return [CAGradientLayer class];
}
@end


// Button that can also accept taps within an invisible margin around its edges
// (touchMargin, 0 by default), so small buttons are still easy to hit.
@interface VNButton : UIButton
@property (nonatomic) CGFloat touchMargin;
@end

@implementation VNButton
- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -self.touchMargin, -self.touchMargin), point);
}
@end


@implementation VNViewController

//////////
// INIT //
//////////

- (void)viewDidLoad {
    
    [super viewDidLoad];
    thisController = self;
    
    normalColor = [UIColor colorWithRed:0.65 green:0.75 blue:0.85 alpha:1];
    selectedColor = [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1];
    borderColor = [normalColor colorWithAlphaComponent:0.65];
    standardBackColor = [UIColor colorWithRed:0.25 green:0.13 blue:0.25 alpha:0.8];
    menuBackColor = [UIColor colorWithRed:0.065 green:0.04 blue:0.07 alpha:0.97];   // about halfway from the sky colour to black

    currentMode = DRAW;
    [self initBackground];

    // Back to front: side tints, sky, menu dimming, button bar / menu panel, menu button.
    [self initMargins];
    [self initSkyView];
    [self initStarsView];
    [self initMenuDim];
    [self initBarView];
    [self initMenuButton];


}


- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (BOOL) prefersHomeIndicatorAutoHidden {
    return YES;
}


// Let a drag that starts near the bottom edge draw a constellation instead of
// immediately triggering the home gesture.
- (UIRectEdge) preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeBottom;
}


// Lay everything out against the real view size and safe area.
//
// iPads: a top bar of buttons, with the star field scaled evenly to fit below it.
// Phones in landscape (compact height): the star field fills the full screen
// height and is stretched sideways halfway between its natural shape and the
// full screen width. The leftover strips at the sides are tinted, and the
// buttons live in a menu that slides out from a button in the top-left corner.
- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat W = bounds.size.width, H = bounds.size.height;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    // The hamburger menu is used on phones in landscape and in any window too
    // narrow for the top bar (e.g. a small iPad window).
    phoneLayout = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) || (W - safe.left - safe.right) < kMinTopBarWidth;
    if (!phoneLayout) menuOpen = NO;

    // The star field is fitted to the space available and may then be
    // stretched along the axis with room to spare: half of the way to filling
    // it, and never more than kMaxStretch.
    CGRect sky;
    CGFloat sx, sy;
    BOOL verticalStretch = NO;
    CGFloat fieldTop = -1;   // >= 0 to place the field at this y instead of centring it
    if (phoneLayout) {
        sky = bounds;   // stars use the full height; sideways they stay clear of the island/notch
        CGFloat fitX = (W - safe.left - safe.right) / kSkyWidth;
        CGFloat fitY = H / kSkyHeight;
        if (fitX <= fitY) {
            sx = fitX;
            sy = MIN(MIN(fitX + 0.5 * (fitY - fitX), fitY), fitX * (1 + kMaxStretch));
            verticalStretch = YES;
        } else {
            // Fit the stars (not the whole field) between equal gaps at the top
            // and bottom: the gap above the highest star when the field fills
            // the height, repeated below the lowest star.
            CGFloat top = [VNData topmostStarY], bottom = [VNData bottommostStarY];
            CGFloat gap = top * fitY;
            sy = (H - 2 * gap) / (bottom - top);
            fieldTop = gap - top * sy;
            sx = MIN(MIN(sy + 0.5 * (W / kSkyWidth - sy), fitX), sy * (1 + kMaxStretch));
        }
    } else {
        barView.frame = CGRectMake(0, safe.top, W, kTopBarHeight);
        CGFloat skyTop = CGRectGetMaxY(barView.frame);
        sky = CGRectMake(safe.left, skyTop, W - safe.left - safe.right, H - skyTop - safe.bottom);
        CGFloat fitX = sky.size.width / kSkyWidth, fitY = sky.size.height / kSkyHeight;
        if (fitX < fitY) {
            // Portrait (taller than the field): fill the width, stretch downwards a little.
            sx = fitX;
            sy = MIN(fitX + 0.5 * (fitY - fitX), fitX * (1 + kMaxPortraitStretch));
            verticalStretch = YES;
        } else {
            sx = sy = fitY;   // landscape: plain fit, as before
        }
    }
    if (sx <= 0 || sy <= 0) sx = sy = 1;
    skyView.frame = sky;

    // Size and centre the star field (drawn unscaled; stars are placed by VNData).
    CGSize field = CGSizeMake(kSkyWidth * sx, kSkyHeight * sy);
    starsView.frame = CGRectMake(floor((sky.size.width - field.width) / 2),
                                 fieldTop >= 0 ? fieldTop : floor((sky.size.height - field.height) / 2),
                                 field.width, field.height);

    if (sx != [VNData fieldScaleX] || sy != [VNData fieldScaleY]) {
        [VNData setFieldScaleX:sx y:sy];
        [starsView refreshForDisplayScale];
    }

    // Text sits over the whole sky area, unscaled, with a readable minimum size.
    textLayer.frame = skyView.bounds;
    textLayer.fieldOrigin = starsView.frame.origin;
    textLayer.textScale = MAX(MIN(sx, sy), kMinTextScale);
    // Words and tercets stay inside the safe area: never under the Dynamic
    // Island or notch, or cut off by a rounded screen corner.
    CGRect safeRect = UIEdgeInsetsInsetRect(bounds, safe);
    textLayer.textArea = CGRectIntersection(textLayer.bounds, [self.view convertRect:safeRect toView:textLayer]);

    // Gradient strips beside the field where there is spare room: left and
    // right on phones; above and below when stretched vertically (iPad
    // portrait). On iPad in landscape, the fade behind the top bar.
    CGRect fieldInView = [skyView convertRect:starsView.frame toView:self.view];
    leftMargin.frame = CGRectMake(0, 0, CGRectGetMinX(fieldInView), H);
    rightMargin.frame = CGRectMake(CGRectGetMaxX(fieldInView), 0, W - CGRectGetMaxX(fieldInView), H);
    leftMargin.hidden = rightMargin.hidden = !(phoneLayout && CGRectGetMinX(fieldInView) > 0.5);

    if (verticalStretch) {
        topFade.frame = CGRectMake(0, 0, W, CGRectGetMinY(fieldInView));
        bottomFade.frame = CGRectMake(0, CGRectGetMaxY(fieldInView), W, H - CGRectGetMaxY(fieldInView));
    } else {
        topFade.frame = CGRectMake(0, 0, W, CGRectGetMaxY(barView.frame));
    }
    topFade.hidden = phoneLayout && !verticalStretch;
    bottomFade.hidden = !verticalStretch;

    // Darker fades only on iPad in portrait.
    CGFloat fadeAlpha = (verticalStretch && !phoneLayout) ? kPortraitFadeAlpha : kFadeAlpha;
    NSArray *fadeColors = @[(id)[UIColor colorWithWhite:0 alpha:0].CGColor, (id)[UIColor colorWithWhite:0 alpha:fadeAlpha].CGColor];
    ((CAGradientLayer *)topFade.layer).colors = fadeColors;
    ((CAGradientLayer *)bottomFade.layer).colors = fadeColors;

    [self layoutMenuChrome];
    [self layoutButtons];
}


///////////////////
// PHONE MENU    //
///////////////////

// Side strips fade from the plain sky background at the field's edge to the
// darker bar tint at the screen's edge.
- (void) initMargins {
    leftMargin = [[VNGradientView alloc] init];
    rightMargin = [[VNGradientView alloc] init];
    for (UIView *m in @[leftMargin, rightMargin]) {
        CAGradientLayer *g = (CAGradientLayer *)m.layer;
        g.colors = @[(id)[UIColor colorWithWhite:0 alpha:0].CGColor,
                     (id)[UIColor colorWithWhite:0 alpha:0.2].CGColor];   // same tint as the iPad bar
        m.userInteractionEnabled = NO;
        [self.view addSubview:m];
    }
    // Gradients run from the inner edge (clear) outwards to the screen edge (dark).
    ((CAGradientLayer *)leftMargin.layer).startPoint = CGPointMake(1, 0.5);
    ((CAGradientLayer *)leftMargin.layer).endPoint = CGPointMake(0, 0.5);
    ((CAGradientLayer *)rightMargin.layer).startPoint = CGPointMake(0, 0.5);
    ((CAGradientLayer *)rightMargin.layer).endPoint = CGPointMake(1, 0.5);

    // iPad: the button bar has no solid tint; instead the sky darkens gradually
    // from the bottom of the bar up to the top of the screen.
    topFade = [[VNGradientView alloc] init];
    CAGradientLayer *tg = (CAGradientLayer *)topFade.layer;
    tg.colors = ((CAGradientLayer *)leftMargin.layer).colors;
    tg.startPoint = CGPointMake(0.5, 1);
    tg.endPoint = CGPointMake(0.5, 0);
    topFade.userInteractionEnabled = NO;
    [self.view addSubview:topFade];

    // Below the field when it is stretched vertically (iPad portrait).
    bottomFade = [[VNGradientView alloc] init];
    CAGradientLayer *bg = (CAGradientLayer *)bottomFade.layer;
    bg.colors = tg.colors;
    bg.startPoint = CGPointMake(0.5, 0);
    bg.endPoint = CGPointMake(0.5, 1);
    bottomFade.userInteractionEnabled = NO;
    bottomFade.hidden = YES;
    [self.view addSubview:bottomFade];
}

// Dims the sky while the menu is open; tapping it closes the menu.
- (void) initMenuDim {
    menuDimView = [[UIView alloc] init];
    menuDimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    menuDimView.alpha = 0;
    menuDimView.userInteractionEnabled = NO;
    [menuDimView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)]];
    [self.view addSubview:menuDimView];
}

// Three thin light-blue lines that turn into an X while the menu is open.
- (void) initMenuButton {
    menuButton = [VNButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake(0, 0, kMenuButtonSize, kMenuButtonSize);
    menuButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    menuButton.layer.cornerRadius = 8;
    menuButton.layer.borderWidth = 1;
    menuButton.layer.borderColor = [normalColor colorWithAlphaComponent:0.45 * 0.65].CGColor;
    menuButton.accessibilityLabel = @"Menu";
    menuButton.alpha = 0.65;   // present but quiet

    NSMutableArray *lines = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 1.5)];
        line.backgroundColor = normalColor;
        line.layer.cornerRadius = 0.75;
        line.userInteractionEnabled = NO;
        line.center = CGPointMake(kMenuButtonSize / 2, kMenuButtonSize / 2 + (i - 1) * kMenuLineSpacing);
        [menuButton addSubview:line];
        [lines addObject:line];
    }
    menuLines = lines;

    [menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuButton addTarget:self action:@selector(menuButtonTouch:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [menuButton addTarget:self action:@selector(menuButtonTouch:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [self.view addSubview:menuButton];
}

- (void) menuButtonTouch:(UIButton *)button {
    UIColor *c = button.isHighlighted ? selectedColor : normalColor;
    for (UIView *line in menuLines) line.backgroundColor = c;
}

- (void) toggleMenu {
    [self setMenuOpen:!menuOpen animated:YES];
}

- (void) closeMenu {
    [self setMenuOpen:NO animated:YES];
}

- (void) setMenuOpen:(BOOL)open animated:(BOOL)animated {
    if (!phoneLayout) open = NO;
    menuOpen = open;
    menuDimView.userInteractionEnabled = open;

    // Stop any slide in progress where it is, then ease to the new state.
    if (menuAnimator.isRunning) {
        [menuAnimator stopAnimation:NO];
        [menuAnimator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
    }
    if (!animated) {
        [self layoutMenuChrome];
        return;
    }
    UICubicTimingParameters *easeInOut = [[UICubicTimingParameters alloc] initWithControlPoint1:CGPointMake(0.65, 0)
                                                                               controlPoint2:CGPointMake(0.35, 1)];
    menuAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:kMenuDuration timingParameters:easeInOut];
    [menuAnimator addAnimations:^{
        [self layoutMenuChrome];
    }];
    [menuAnimator startAnimation];
}

// How far the menu button and menu items sit from the screen edges. Screens
// with rounded corners (all with a home indicator) need more room, so the
// button stays well clear of the curve.
- (CGFloat) cornerInset {
    return self.view.safeAreaInsets.bottom > 0 ? kRoundedCornerInset : kMenuButtonInset;
}

// Left edge of the menu items: lined up with the menu button, unless the
// Dynamic Island / notch is on the left (the phone is rotated with its top to
// the left), in which case they stay just inside the safe area, clear of it.
- (CGFloat) menuItemsX {
    CGFloat inset = self.view.safeAreaInsets.left;
    UIInterfaceOrientation o = self.view.window.windowScene.interfaceOrientation;
    BOOL housingOnLeft = (o == UIInterfaceOrientationLandscapeRight);
    CGFloat corner = [self cornerInset];
    if (inset > corner && housingOnLeft) return inset;
    return corner;
}

// Turning the phone end over (landscape left <-> right) keeps the same size,
// but moves the island to the other side, so lay the menu out again.
- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // If the Info popup is open when the device rotates (or the window is
    // resized, or the iPhone Duo folds), it fades out as the rotation starts,
    // and fades back in, laid out for the new size (two columns or one, its
    // width and height, and Close), once the rotation has finished.
    BOOL infoOpen = curtain.superview && infoModalView.superview == curtain;
    if (infoOpen) {
        UIView *modal = infoModalView;
        modal.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            modal.alpha = 0;
        } completion:nil];
    }

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        if (infoOpen && infoModalView.superview == curtain) [self relayoutOpenInfo];
    }];
}

// Positions the menu panel, dimming and hamburger for the current state.
- (void) layoutMenuChrome {
    CGFloat H = self.view.bounds.size.height;

    menuButton.hidden = !phoneLayout;
    menuDimView.hidden = !phoneLayout;
    barView.layer.shadowOpacity = phoneLayout ? 0.35 : 0;

    if (!phoneLayout) {
        barView.backgroundColor = [UIColor clearColor];   // the top fade provides the shading
        return;
    }

    barView.backgroundColor = menuBackColor;
    CGFloat panelWidth = [self menuItemsX] + kMenuItemWidth + [self cornerInset];
    CGFloat closedX = -(panelWidth + 20);   // fully off screen, shadow included
    barView.frame = CGRectMake(menuOpen ? 0 : closedX, 0, panelWidth, H);
    menuDimView.frame = self.view.bounds;
    menuDimView.alpha = menuOpen ? 1 : 0;

    // Top-left corner of the whole screen (in the tinted strip where there is
    // one), inset just enough to clear rounded display corners. When the island
    // or notch is on the left it moves right to line up with the menu items.
    menuButton.frame = CGRectMake([self menuItemsX], [self cornerInset], kMenuButtonSize, kMenuButtonSize);
    // Generous invisible tap area for the hamburger; none for the X, which sits
    // just above the menu items.
    ((VNButton *)menuButton).touchMargin = menuOpen ? 0 : 14;
    CGFloat d = kMenuLineSpacing;
    menuLines[0].transform = menuOpen ? CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, d), M_PI_4) : CGAffineTransformIdentity;
    menuLines[2].transform = menuOpen ? CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, -d), -M_PI_4) : CGAffineTransformIdentity;
    menuLines[1].alpha = menuOpen ? 0 : 1;
    menuLines[1].transform = menuOpen ? CGAffineTransformMakeScale(0.2, 1) : CGAffineTransformIdentity;
}


////////////////
// BACKGROUND //
////////////////

// The background is a left-to-right gradient. Each end drifts slowly between
// shades of purple (more reddish, more blue) on its own random schedule, so
// the two sides never move in step and the sky between them blends smoothly.

typedef struct {
    CGFloat from[3], to[3];          // RGB
    CFTimeInterval start, duration;
    CFTimeInterval minDuration, maxDuration;
} VNColorDrift;

static VNColorDrift leftDrift, rightDrift;
static CAGradientLayer *skyGradient;
static CADisplayLink *backgroundTicker;

static void randomSkyShade(CGFloat rgb[3]) {
    rgb[0] = 0.12 + ABF(0.06);
    rgb[1] = 0.04 + ABF(0.06);
    rgb[2] = 0.14 + ABF(0.06);
}

static void startDrift(VNColorDrift *d, CFTimeInterval now) {
    randomSkyShade(d->to);
    d->start = now;
    d->duration = d->minDuration + ABF(d->maxDuration - d->minDuration);
}

// Current colour of one side, moving on to a new target when one is reached.
static UIColor *driftColor(VNColorDrift *d, CFTimeInterval now) {
    CGFloat t = (now - d->start) / d->duration;
    if (t >= 1) {
        memcpy(d->from, d->to, sizeof d->from);
        startDrift(d, now);
        t = 0;
    }
    t = t * t * (3 - 2 * t);   // ease in and out
    return [UIColor colorWithRed:d->from[0] + (d->to[0] - d->from[0]) * t
                           green:d->from[1] + (d->to[1] - d->from[1]) * t
                            blue:d->from[2] + (d->to[2] - d->from[2]) * t
                           alpha:0.90];
}

- (void) initBackground {
    VNGradientView *bg = [[VNGradientView alloc] initWithFrame:self.view.bounds];
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bg.userInteractionEnabled = NO;
    [self.view insertSubview:bg atIndex:0];
    self.view.backgroundColor = [UIColor clearColor];

    skyGradient = (CAGradientLayer *)bg.layer;
    skyGradient.startPoint = CGPointMake(0, 0.5);
    skyGradient.endPoint = CGPointMake(1, 0.5);

    // Both sides start from the launch colour, then wander off independently.
    CFTimeInterval now = CACurrentMediaTime();
    CGFloat launch[3] = { 0.14, 0.09, 0.15 };
    memcpy(leftDrift.from, launch, sizeof launch);
    memcpy(rightDrift.from, launch, sizeof launch);
    leftDrift.minDuration = 14;  leftDrift.maxDuration = 18;
    rightDrift.minDuration = 17; rightDrift.maxDuration = 23;
    startDrift(&leftDrift, now);
    startDrift(&rightDrift, now);
    [self tickBackground];

    // The change is so slow that 10 updates a second is visually seamless.
    backgroundTicker = [CADisplayLink displayLinkWithTarget:self selector:@selector(tickBackground)];
    backgroundTicker.preferredFramesPerSecond = 10;
    [backgroundTicker addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) tickBackground {
    CFTimeInterval now = CACurrentMediaTime();
    UIColor *left = driftColor(&leftDrift, now);
    UIColor *right = driftColor(&rightDrift, now);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    skyGradient.colors = @[(id)left.CGColor, (id)right.CGColor];
    [CATransaction commit];
}

+ (void) suspendTimers {
    backgroundTicker.paused = YES;
    [starsView suspendTimers];
}

+ (void) resumeTimers {
    backgroundTicker.paused = NO;
    [starsView resumeTimers];
}


- (void) initBarView {
    barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kSkyWidth, kTopBarHeight)];
    barView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    barView.layer.shadowColor = [UIColor blackColor].CGColor;
    barView.layer.shadowRadius = 12;
    barView.layer.shadowOffset = CGSizeMake(2, 0);
    barView.layer.shadowOpacity = 0;
    [self.view addSubview:barView];

    [self initButtons];
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

    textLayer = [[VNTextView alloc] initWithFrame:skyView.bounds];
    [skyView addSubview:textLayer];
    starsView.textView = textLayer;
}



/////////////
// BUTTONS //
/////////////

- (UIButton *) createButtonWithFrame:(CGRect)frame title:(NSString *)title tag:(buttonType)tag {
    
    UIButton *button = [VNButton buttonWithType:UIButtonTypeCustom];
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
    [button.layer setBorderColor:borderColor.CGColor];
    [button.layer setCornerRadius:8.0f];
    [button addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}



- (void) initButtons {

    drawButton   = [self createButtonWithFrame:CGRectZero title:@"Draw" tag:MODE];
    consButton   = [self createButtonWithFrame:CGRectZero title:@"Constellations" tag:MODE];
    waveButton   = [self createButtonWithFrame:CGRectZero title:@"WaveTercets" tag:MODE];
    oracleButton = [self createButtonWithFrame:CGRectZero title:@"Oracle" tag:MODE];
    clearButton  = [self createButtonWithFrame:CGRectZero title:@"Clear" tag:MODE];
    infoButton   = [self createButtonWithFrame:CGRectZero title:@"Info" tag:MODE];

    modeButtons = @[drawButton, consButton, waveButton, oracleButton];
    modeButtonWidths = @[@70, @135, @125, @80];
    utilityButtons = @[clearButton, infoButton];
    utilityButtonWidths = @[@70, @65];

    for (UIButton *b in [modeButtons arrayByAddingObjectsFromArray:utilityButtons]) {
        [barView addSubview:b];
    }

    drawButton.selected = YES;
    activeNavButton = drawButton;
}


// Top bar: mode buttons on the left, Clear and Info on the right.
// Phone menu panel: mode buttons below the menu button, Clear and Info at the bottom.
- (void) layoutButtons {
    CGSize bar = barView.bounds.size;
    UIEdgeInsets safe = self.view.safeAreaInsets;

    if (phoneLayout) {
        CGFloat x = [self menuItemsX], gap = kMenuItemGap;
        CGFloat w = kMenuItemWidth, h = kMenuItemHeight;
        UIFont *font = [UIFont fontWithName:@"EuphemiaUCAS" size:kMenuItemFontSize];
        for (UIButton *b in [modeButtons arrayByAddingObjectsFromArray:utilityButtons]) b.titleLabel.font = font;

        CGFloat y = [self cornerInset] + kMenuButtonSize + gap;   // below the menu button, same spacing as the items
        for (UIButton *b in modeButtons) {
            b.frame = CGRectMake(x, y, w, h);
            y += h + gap;
        }

        y = bar.height - safe.bottom - [self cornerInset] - h;
        for (UIButton *b in [utilityButtons reverseObjectEnumerator]) {
            b.frame = CGRectMake(x, y, w, h);
            y -= h + gap;
        }
        return;
    }

    UIFont *font = [UIFont fontWithName:@"EuphemiaUCAS" size:14];
    for (UIButton *b in [modeButtons arrayByAddingObjectsFromArray:utilityButtons]) b.titleLabel.font = font;

    CGFloat margin = 20, gap = 10, y = 10, h = 40;

    // Each side keeps clear of its own safe-area inset (e.g. the iPhone Duo's
    // vertical status bar on one edge).
    CGFloat x = safe.left + margin;
    for (NSUInteger i = 0; i < modeButtons.count; i++) {
        CGFloat w = modeButtonWidths[i].doubleValue;
        modeButtons[i].frame = CGRectMake(x, y, w, h);
        x += w + gap;
    }

    x = bar.width - safe.right - margin;
    for (NSInteger i = (NSInteger)utilityButtons.count - 1; i >= 0; i--) {
        CGFloat w = utilityButtonWidths[i].doubleValue;
        x -= w;
        utilityButtons[i].frame = CGRectMake(x, y, w, h);
        x -= gap;
    }
}



- (void) switchToDrawMode {
    currentMode = DRAW;
    if(activeNavButton) activeNavButton.selected = NO;
    activeNavButton = drawButton;
    drawButton.selected = YES;
}


// Space available for modals: the safe area, less a small margin. The insets
// are made symmetrical so popups sit in the true centre of the screen (on
// phones the home-indicator inset at the bottom would otherwise push them up).
- (CGRect) modalArea {
    UIEdgeInsets s = self.view.safeAreaInsets;
    // Horizontally, each edge keeps its own inset, so popups centre in the space
    // beside a one-sided vertical bar. Vertically, the larger inset is used on
    // both edges so popups sit in the true centre of the screen (by design).
    CGFloat v = MAX(s.top, s.bottom);
    return CGRectInset(UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(v, s.left, v, s.right)), 10, 10);
}

- (void) presentModal:(UIView *)modal {
    [self presentModal:modal dimBackground:YES];
}

// dimBackground: NO leaves the sky behind the popup undimmed (used for Info,
// whose dark panel would otherwise blend into a darkened sky). The curtain is
// still there, invisible, so a tap outside the popup closes it.
// Centres a popup in the available area, shrinking it slightly if it does not
// fit (e.g. the Oracle list on an iPhone).
- (void) placeModal:(UIView *)modal {
    CGRect area = [self modalArea];
    CGFloat fit = MIN(1.0, MIN(area.size.width / modal.bounds.size.width, area.size.height / modal.bounds.size.height));
    modal.transform = CGAffineTransformMakeScale(fit, fit);
    modal.center = CGPointMake(CGRectGetMidX(area), CGRectGetMidY(area));
}

- (void) presentModal:(UIView *)modal dimBackground:(BOOL)dim {
    curtain = [[VNBlackCurtain alloc] initWithFrame:self.view.bounds];
    if (!dim) curtain.backgroundColor = [UIColor clearColor];
    curtain.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:curtain];

    [self placeModal:modal];
    modal.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                             UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [curtain addSubview:modal];
    [curtain show];
}


- (void) buttonPress:(UIButton *)button {
    
    NSString *bt = [button currentTitle];

    // Picking anything from the phone menu slides it away.
    if (button.tag == MODE && menuOpen) [self closeMenu];
    
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
            [self presentModal:[self infoModal] dimBackground:NO];
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
    [modal.layer setBorderColor:borderColor.CGColor];
    [modal.layer setCornerRadius:14.0f];
    modal.userInteractionEnabled = YES;
    modal.backgroundColor = standardBackColor;

    return modal;
}

// Replaces a popup's flat background with a still, diagonal gradient from a
// reddish purple (top left) to a bluish purple (bottom right), like the sky's
// drifting background. Both ends are the standard popup purple turned 20°
// towards red and towards blue, at the same brightness and opacity.
- (void) applyGradientBackground:(UIView *)modal {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = modal.bounds;
    g.cornerRadius = modal.layer.cornerRadius;
    g.colors = @[(id)[UIColor colorWithRed:0.25 green:0.13 blue:0.21 alpha:0.8].CGColor,
                 (id)[UIColor colorWithRed:0.21 green:0.13 blue:0.25 alpha:0.8].CGColor];
    g.startPoint = CGPointMake(0, 0);
    g.endPoint = CGPointMake(1, 1);
    modal.backgroundColor = [UIColor clearColor];
    [modal.layer insertSublayer:g atIndex:0];
}

// Size of the Info popup for the current layout. Full size (two columns) on
// iPads in landscape; otherwise a single scrolling column: 75% of the room on
// phones, 62% of the screen's width on iPads in portrait or in small windows
// (and the iPhone Duo's inner screen).
- (void) infoGeometryWidth:(CGFloat *)wOut height:(CGFloat *)hOut compact:(BOOL *)compactOut {
    CGRect area = [self modalArea];
    CGFloat w = MIN(910, area.size.width), h = MIN(660, area.size.height);
    BOOL compact = (w < 910 || h < 660);
    if (compact && phoneLayout) w = round(w * 0.75);   // a narrower column reads better on phones
    if (!phoneLayout && (compact || [self infoIsTall])) {
        w = MIN(round(self.view.bounds.size.width * 0.62), area.size.width);
        h = area.size.height;
        // When it runs this tall, keep it clear of the top bar (by the same
        // amount at the bottom, so it stays centred).
        CGFloat overlap = CGRectGetMaxY(barView.frame) + 10 - CGRectGetMinY(area);
        if (overlap > 0) h -= 2 * overlap;
        compact = YES;
    }
    if (wOut) *wOut = w;
    if (hOut) *hOut = h;
    if (compactOut) *compactOut = compact;
}

// The Info popup, drawn natively (VNInfoView), so it appears at once and is
// exactly as tall as its content (up to the room available, then it scrolls).
- (UIView *) infoModal {
    UIView *modal = [self createModalWithWidth:100 andHeight:100];
    modal.backgroundColor = menuBackColor;   // same dark purple as the phone menu panel
    modal.layer.borderWidth = 0;              // edge-less, like the slide-out menu
    [self fillInfoModal:modal];
    infoModalView = modal;
    return modal;
}

// Lays out the Info popup's contents (and its size) for the current layout.
// Also used to rebuild an open popup when the screen changes size.
- (void) fillInfoModal:(UIView *)modal {
    CGFloat w, maxH;
    BOOL compact;
    [self infoGeometryWidth:&w height:&maxH compact:&compact];

    VNInfoView *content = [[VNInfoView alloc] initWithSingleColumn:compact];
    CGFloat h = MIN(ceil([content layoutForWidth:w]), maxH);

    for (UIView *v in [modal.subviews copy]) [v removeFromSuperview];
    modal.transform = CGAffineTransformIdentity;
    modal.bounds = CGRectMake(0, 0, w, h);
    content.frame = modal.bounds;
    [modal addSubview:content];

    UIButton *b;
    if (compact) {
        // Bottom right corner; matches the menu buttons, with a larger invisible tap area.
        b = [self createButtonWithFrame:CGRectMake(w - 16 - kMenuItemWidth, h - 16 - kMenuItemHeight, kMenuItemWidth, kMenuItemHeight)
                                  title:@"Close" tag:CLOSE];
        b.titleLabel.font = [UIFont fontWithName:@"EuphemiaUCAS" size:kMenuItemFontSize];
        ((VNButton *)b).touchMargin = 12;   // stays inside the popup's 16pt edge
    } else {
        // On the same row as the SpringGun Press logo, right-aligned with the notes.
        CGFloat closeY = MIN(round(CGRectGetMidY(content.logoFrame) - 20), h - 40 - 16);
        b = [self createButtonWithFrame:CGRectMake(w - 38 - 110, closeY, 110, 40) title:@"Close" tag:CLOSE];
    }
    [modal addSubview:b];
}

// Rebuilds the open (faded-out) Info popup for the current size and fades it
// back in.
- (void) relayoutOpenInfo {
    UIView *modal = infoModalView;
    [modal.layer removeAllAnimations];   // in case the fade-out is still running
    [UIView performWithoutAnimation:^{
        [self fillInfoModal:modal];
        [self placeModal:modal];
        modal.alpha = 0;
    }];
    modal.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        modal.alpha = 1;
    } completion:nil];
}

// iPad in portrait (not a phone, and taller than wide).
- (BOOL) infoIsTall {
    CGSize s = self.view.bounds.size;
    return !phoneLayout && s.height > s.width;
}


// Popup buttons. On phones they match the slide-out menu's buttons (height,
// text size and spacing); on iPads they keep their original size.
- (UIButton *) popupButtonWithFrame:(CGRect)frame title:(NSString *)title tag:(buttonType)tag {
    UIButton *b = [self createButtonWithFrame:frame title:title tag:tag];
    if (phoneLayout) b.titleLabel.font = [UIFont fontWithName:@"EuphemiaUCAS" size:kMenuItemFontSize];
    return b;
}

// Lays out a column-major grid of popup buttons and returns the popup.
- (UIView *) popupWithTitles:(NSArray<NSString *> *)titles rows:(int)rows itemWidth:(CGFloat)w tag:(buttonType)tag {
    CGFloat pad = phoneLayout ? 16 : 20;
    CGFloat h = phoneLayout ? kMenuItemHeight : 40;
    CGFloat gap = phoneLayout ? kMenuItemGap : 10;
    CGFloat colGap = phoneLayout ? kMenuItemGap : 10;
    int cols = (int)((titles.count + rows - 1) / rows);

    UIView *modal = [self createModalWithWidth:pad * 2 + cols * w + (cols - 1) * colGap
                                     andHeight:pad * 2 + rows * h + (rows - 1) * gap];
    for (int i = 0; i < titles.count; i++) {
        int col = i / rows, row = i % rows;
        CGRect f = CGRectMake(pad + col * (w + colGap), pad + row * (h + gap), w, h);
        [modal addSubview:[self popupButtonWithFrame:f title:titles[i] tag:tag]];
    }
    [self applyGradientBackground:modal];
    return modal;
}

- (UIView *) constellationsModal {
    NSArray *cs = @[@"swimmer", @"conductor", @"broom", @"dipper", @"twins",
                    @"bull", @"embryo", @"goose", @"infinity", @"dragonfly"];
    return [self popupWithTitles:cs rows:5 itemWidth:(phoneLayout ? kMenuItemWidth : 120) tag:CONSTELLATION];
}


- (UIView *) oracleModal {
    NSArray *cs = @[@"Whose body?",
                    @"How to know?",
                    @"Why care?",
                    @"What do I love?",
                    @"Where to build a bridge?",
                    @"When did you say?",
                    @"Which one?"];
    // Wider than the menu buttons so the longest question fits.
    return [self popupWithTitles:cs rows:7 itemWidth:(phoneLayout ? 224 : 250) tag:ORACLEQUESTION];
}


- (UIView *) stardateModal {
    
    CGFloat buttonHeight = phoneLayout ? kMenuItemHeight : 40;
    UIView *modal = [self createModalWithWidth:290 andHeight:140 + buttonHeight];

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

    UIButton *b = [self popupButtonWithFrame:CGRectMake(20, 120, 250, buttonHeight) title:@"teleport" tag:STARDATE];
    [modal addSubview:b];

    [self applyGradientBackground:modal];
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
