//
//  VNTextView.h
//  Vniverse
//
//  Created by Ian Hatcher on 2/13/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNTextView : UIView

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
