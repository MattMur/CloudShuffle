//
//  TransitionController.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/7/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "CustomNavigationController.h"

@implementation CustomNavigationController

@synthesize navBar;
@synthesize activeViewControllerIndex;

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)] autorelease];
    self.activeViewControllerIndex = -1;
}



 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
    [super viewDidLoad];
    
     self.navBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
     [self.view addSubview:self.navBar];
     self.navBar.hidden = NO;
     self.navBar.delegate = self;

 }
 

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View Containment
//http://developer.apple.com/library/ios/#documentation/uikit/reference/UIViewController_Class/Reference/Reference.html

- (void) pushViewController:(UIViewController*)toViewController animated:(BOOL)animated
{
    [self addChildViewController:toViewController];
    [self.view addSubview:toViewController.view];
    
    UIViewController *fromViewController = nil;
    
    if (activeViewControllerIndex >= 0) {
        fromViewController = [self.childViewControllers 
                              objectAtIndex:self.activeViewControllerIndex];
        
        
        
        double time = ( animated ? 1.0 : 0);
        [self transitionFromViewController:fromViewController toViewController:toViewController duration:time options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = CGRectMake(320, 0, 320, 460);
            toViewController.view.frame = self.view.frame;
        } completion:^(BOOL finished) {
            [toViewController didMoveToParentViewController:self];
        }];
    } else {
        toViewController.view.frame = self.view.frame;
        [toViewController didMoveToParentViewController:self];
    }
    
    self.activeViewControllerIndex++;
    

}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *fromViewController = nil;
    
    if (activeViewControllerIndex >= 0) {
        fromViewController = [self.childViewControllers objectAtIndex: self.activeViewControllerIndex];
        [fromViewController removeFromParentViewController];
        
        UIViewController *toViewController = [self.childViewControllers 
                                  objectAtIndex:self.activeViewControllerIndex];
        
        double time = ( animated ? 1.0 : 0);
        [self transitionFromViewController:fromViewController toViewController:toViewController duration:time options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = CGRectMake(320, 0, 320, 460);
            toViewController.view.frame = self.view.frame;
        } completion:^(BOOL finished) {
            self.activeViewControllerIndex--;
        }];
    }
    
    return fromViewController;
}

#pragma mark - NavigationBar Delegate Methods

// called to push. return NO not to.
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item
{
    return YES;
}

// called at end of animation of push or immediately if not animated
- (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item
{
    
}

// same as push methods
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    return YES;
}

- (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item
{
    
}




- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
