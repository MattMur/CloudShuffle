//
//  AppDelegate.h
//  CloudShuffle
//
//  Created by Matt Murray on 9/29/12.
//  Copyright (c) 2012 Special Ops Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "SoundCloudAPIManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, SoundCloudLogonDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (weak, nonatomic) Reachability *iReach; //Used to detect internet connectivity


@end
