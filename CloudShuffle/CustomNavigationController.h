//
//  TransitionController.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/7/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomNavigationController : UIViewController <UINavigationBarDelegate>

@property (retain, nonatomic) UINavigationBar *navBar;
@property (assign, nonatomic) int activeViewControllerIndex;

//View Containment
- (void) pushViewController:(UIViewController*)toViewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated; 


@end
