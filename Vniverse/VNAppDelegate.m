//
//  VNAppDelegate.m
//  Vniverse
//
//  Created by Ian Hatcher on 1/18/14.
//  Copyright (c) 2014 Ian Hatcher. All rights reserved.
//

#import "VNAppDelegate.h"
#import "VNViewController.h"

@implementation VNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                                                  sessionRole:connectingSceneSession.role];
    config.delegateClass = [VNSceneDelegate class];
    return config;
}

@end


@implementation VNSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [[VNViewController alloc] init];
    [self.window makeKeyAndVisible];
}

- (void)sceneWillResignActive:(UIScene *)scene {
    [VNViewController suspendTimers];
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [VNViewController resumeTimers];
}

@end
