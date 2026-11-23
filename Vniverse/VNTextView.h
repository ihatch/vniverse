//
//  VNTextView.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/13/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

// Shows words, numbers and tercets over the star field. It is not scaled with
// the field: star positions come from VNData pointForStar: offset by
// fieldOrigin (where the star view sits within this view), and text is drawn
// at textScale, which never drops below a readable size.
@interface VNTextView : UIView

@property (nonatomic) CGPoint fieldOrigin;
@property (nonatomic) CGFloat textScale;

// Where text may appear, in this view's coordinates: the safe area, clear of
// the Dynamic Island, notch and rounded corners. Defaults to the whole view.
@property (nonatomic) CGRect textArea;

- (void) showNumberForStar:(int)starID;
- (void) showWordForStar:(int)starID;
- (void) showWordInColorForStar:(int)starID;
- (void) showQuickWordForStar:(int)starID;
- (void) showAllNumbers;
- (void) showTercet:(int)tercet;
- (void) showTwoTercets:(int)a and:(int)b;

- (void) clearTercet;
- (void) clearAllText;

@end
