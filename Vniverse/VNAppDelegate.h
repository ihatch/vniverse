//
//  VNAppDelegate.h
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNAppDelegate : UIResponder <UIApplicationDelegate>

@end


// Owns the app's window. iOS now requires the scene-based life cycle,
// so the window and the pause/resume hooks live here rather than in
// the app delegate.
@interface VNSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
