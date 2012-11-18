//
//  ChambermaidAppDelegate.h
//  chambermaid-ios
//
//  Created by Martin Jansen on 18.11.12.
//  Copyright (c) 2012 Bauer + Kirch GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChambermaidViewController;

@interface ChambermaidAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ChambermaidViewController *viewController;

@end
