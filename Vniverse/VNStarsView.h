//
//  DrawStarLineView.h
//  Vniverse
//

#import <UIKit/UIKit.h>
typedef enum { DRAW, CONSTELLATIONS, WAVETERCETS, ORACLE } appMode;

@interface VNStarsView : UIView

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


@end
