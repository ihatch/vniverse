//
//  DrawStarLineView.h
//  Vniverse
//

#import <UIKit/UIKit.h>
typedef enum { DRAW, CONSTELLATIONS, WAVETERCETS, ORACLE } appMode;

@class VNTextView;


@interface VNStarsView : UIView <CAAnimationDelegate>

// Words and tercets are drawn in a separate, unscaled view that sits over
// the star field, so text stays readable when the field is scaled down.
@property (nonatomic, strong) VNTextView *textView;

- (void) initStars;
- (void) startDrawingConstellation;
- (void) moveFingerWhileDrawingConstellation:(CGPoint)point;

- (void) clearScreen;
- (void) showTercet:(int)tercet;
- (void) showCanonConstellation:(NSString *)name;
- (void) showAllNumbers;
- (void) startPlayingTercets:(int)tercet;
- (void) nextTercet;
- (void) showBridge;
- (void) showOracleAnswer;
- (void) showOracleHowToKnow;
- (void) hideStars;

- (void) tapSkyWithMode:(appMode)mode point:(CGPoint)point;
- (void) suspendTimers;
- (void) resumeTimers;
- (void) refreshForDisplayScale;


@end
