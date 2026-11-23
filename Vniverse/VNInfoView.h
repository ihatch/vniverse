//
//  VNInfoView.h
//  Vniverse
//
//  The contents of the Info popup, drawn natively (no web view), so it appears
//  instantly and sizes itself exactly.
//

#import <UIKit/UIKit.h>

@interface VNInfoView : UIView

// singleColumn: one scrolling column (phones, iPad portrait, small windows).
// Otherwise two columns at the full 910pt width (iPad landscape).
- (instancetype) initWithSingleColumn:(BOOL)singleColumn;

// Lays the content out for this width and returns its natural height. In the
// two-column layout this includes the row beside the logo where Close sits.
- (CGFloat) layoutForWidth:(CGFloat)width;

// Two-column layout: the logo's frame, so the popup can put Close beside it.
@property (nonatomic, readonly) CGRect logoFrame;

@end
