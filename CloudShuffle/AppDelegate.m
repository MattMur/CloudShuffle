//
//  AppDelegate.m
//  CloudShuffle
//
//  Created by Matt Murray on 9/29/12.
//  Copyright (c) 2012 Special Ops Development. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "UIAlertView+Blocks.h"
#import "UserDataManager.h"
#import "Reachability.h"
#import "UIAlertView+Blocks.h"
//#import "TestFlight.h"
#import "SCSPlayer.h"

@interface AppDelegate ()
@property (nonatomic, strong) UIViewController *noConnectionViewController;
@end


@implementation AppDelegate
@synthesize navController = _navController;
@synthesize iReach = _iReach;
@synthesize noConnectionViewController = _noConnectionViewController;



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //self.window

    HomeViewController *homeViewController = [[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:nil];
    self.navController = [[UINavigationController alloc] initWithRootViewController:homeViewController];
    
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    
    // [TestFlight takeOff:@"a888b6e37866cbdd062346b797491a49_MTIzNzcyMjAxMi0wOC0yMiAwMDoxOTozNy43MDM0Mzg"];
    //// [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    
    
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	BOOL didHandleURL = NO;
	if (launchURL) {
		didHandleURL = [SCSoundCloud handleRedirectURL:launchURL];
	}
    
    //verify internet reachability
    self.iReach = [Reachability reachabilityWithHostname:@"www.google.com"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    [self.iReach startNotifier];
    
    //logon
    if ([SCSoundCloud account] == nil) {
        [SoundCloudAPIManager sharedInstance].delegateLogon = self;
        [[SoundCloudAPIManager sharedInstance] login];
    } else {
        //refresh data
        [[SoundCloudAPIManager sharedInstance] requestMeInfo];
        [homeViewController startRefreshIndicators];
        [homeViewController didLogin];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"logon" object:nil];
    }
	return didHandleURL;
}



#pragma mark - Logon Delegate Methods

- (void)presentLoginController:(UIViewController *)loginVC
{
    // [TestFlight passCheckpoint:@"Attempting authentication"];
    [self.navController presentViewController:loginVC animated:YES completion:nil];
}


- (void)didCompleteLogin
{
    // [TestFlight passCheckpoint:@"Signed in"];
    //[self.navController dismissViewControllerAnimated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logon" object:nil];
    
    //Make request for user info
    [[SoundCloudAPIManager sharedInstance] requestMeInfo];
}

#pragma mark - Reachability

// Handles what to do when no internet connection is availible
- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *iReach = [notification object];
    
    switch (iReach.currentReachabilityStatus) {
        case NotReachable:{
            //Push on VC that disables all actions and explains that internet is not availible
            if (!self.noConnectionViewController.navigationController) {
                [self.navController pushViewController:self.noConnectionViewController animated:NO];
                // [TestFlight passCheckpoint:@"Lost internet connection"];
            }
            break;
        }
            
        case ReachableViaWiFi:
            //remove the viewcontroller if it is on the stack
            if (self.noConnectionViewController.navigationController) {
                [self.navController popViewControllerAnimated:NO];
            }
            break;
        case ReachableViaWWAN:
            //remove the viewcontroller if it is on the stack
            if (self.noConnectionViewController.navigationController) {
                [self.navController popViewControllerAnimated:NO];
            }
            break;
            
        default:
            break;
    }
}

// Getter for no connection viewController
- (UIViewController *)noConnectionViewController
{
    if (!_noConnectionViewController) {
        UIView *noConnectionView = [[[NSBundle mainBundle] loadNibNamed:@"NoInternetView" owner:nil options:nil] objectAtIndex:0];
        _noConnectionViewController = [[UIViewController alloc] init];
        _noConnectionViewController.view = noConnectionView;
        [_noConnectionViewController.navigationItem setHidesBackButton:YES];
        
        _noConnectionViewController.navigationItem.titleView = [[[NSBundle mainBundle] loadNibNamed:@"TitleView" owner:nil options:nil] objectAtIndex:0];
    }
    return _noConnectionViewController;
}


#pragma mark - Remote Control Events

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        SCSPlayer *player = [SCSPlayer sharedInstance];
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (player.audioStream.playState == SCAudioStreamState_Playing) {
                    [player pause];
                } else {
                    [player play];
                }
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                [player previousSong];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [player nextSong];
                break;
                
            default:
                break;
        }
    }
}


#pragma mark - Application Lifetime 

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;
{
    return NO;//[SCSoundCloud handleRedirectURL:url];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    // [TestFlight passCheckpoint:@"Application will resign active"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    // [TestFlight passCheckpoint:@"Application did enter background"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    // [TestFlight passCheckpoint:@"Application will enter foreground"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // [TestFlight passCheckpoint:@"Application did become active"];
    //[[SoundCloudAPIManager scAPI] checkAuthentication];
    
    //make sure all login calls still get sent back to app delegate
    [SoundCloudAPIManager sharedInstance].delegateLogon = self;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/*
 #pragma mark - SCSoundCloudAPIAuthenticationDelegate

- (void)soundCloudAPIDidAuthenticate;
{
    // [TestFlight passCheckpoint:@"Signed in"];
    //dismiss logonVC if neccesary
    [self.customNavController dismissViewControllerAnimated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logon" object:nil];
    
    //Make request for user info
    [[SoundCloudAPIManager sharedInstance] requestMeInfo];
}

- (void)soundCloudAPIDidResetAuthentication;
{
    // the user did signed off. Clear data. Send notification to rest of the app
    // [TestFlight passCheckpoint:@"Signed out"];
    [[UserDataManager sharedInstance] clearAllData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logoff" object:nil];
    
    //Attempt to log in again
    [[SoundCloudAPIManager scAPI] checkAuthentication];
}

- (void)soundCloudAPIDidFailToGetAccessTokenWithError:(NSError *)error;
{
    // inform your user and let him retry the authentication
    // [TestFlight passCheckpoint:@"Authentication failed"];
    NSString *message = [NSString stringWithFormat:@"%@. Please try again. ", error.localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    [alert release];
}


////TODO: PresentViewConttroller
- (void)soundCloudAPIWillDisplayLoginViewController:(SCLoginViewController *)soundCloudViewController
{
    //NSLog(@"Will display loginVC");
    //[self.customNavController presentModalViewController:soundCloudViewController animated:YES];
}

- (void)soundCloudAPIDisplayViewController:(UIViewController *)soundCloudViewController
{
    //NSLog(@"Display VC");
    // [TestFlight passCheckpoint:@"Attempting authentication"];
    [self.customNavController presentModalViewController:soundCloudViewController animated:YES];
}

- (void)soundCloudAPIDismissViewController:(UIViewController *)soundCloudViewController
{
    NSLog(@"Dismiss VC");
    [self.customNavController dismissViewControllerAnimated:YES completion:nil];
}
*/





@end
