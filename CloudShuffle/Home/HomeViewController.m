//
//  ViewController.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 12/31/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "HomeViewController.h"
#import "MeModel.h"
#import "TrackModel.h"
#import "PlaylistModel.h"
#import "PlaylistViewController.h"
#import "UserDataManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SCSPlayer.h"
#import "PlaylistTableViewCell.h"
#import "SCSUtilities.h"
#import "UIAlertView+Blocks.h"
#import "MenuItemModel.h"
#import "Reachability.h"
//#import "TestFlight.h"
#import "SVPullToRefresh.h"

#define SEEN_FIRST_TIME_MESSAGE @"firstTime"

typedef enum {
    menuItemLog = 0
} MenuItemType;

@interface HomeViewController (HomeViewController) 
- (void)loadPlaylistType:(NSString *)playlistType;
- (void)showInfoPanel;
- (void)dismissInfoPanel;
@end

@implementation HomeViewController

@synthesize menu = _menu;
@synthesize infoPanel = _infoPanel;


#pragma mark - KVO

// Observe UserData for changes in playlists. Update song count.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    int row = -1; // used to stop the loading indicator at that specific row
    if ([keyPath isEqual:@"favoritesCount"]) {
        self.favoriteTracksCountLabel.text = [NSString stringWithFormat:@"%@", [change objectForKey:NSKeyValueChangeNewKey]];
        row = 2;
    } else if([keyPath isEqual:@"bandTracksCount"]) {
        self.bandTracksCountLabel.text = [NSString stringWithFormat:@"%@", [change objectForKey:NSKeyValueChangeNewKey]];
        row = 0;
    } else if ([keyPath isEqual:@"bandFavoritesCount"]) {
        self.bandFavoriteTracksCountLabel.text = [NSString stringWithFormat:@"%@", 
                                                  [change objectForKey:NSKeyValueChangeNewKey]];
        row = 1;
    } else if ([keyPath isEqual:@"meInfo"]) {
        
        //Check if the user if a first timer
        //Display message once per user
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:SEEN_FIRST_TIME_MESSAGE]) {
            [self showInfoPanel];
            [defaults setBool:YES forKey:SEEN_FIRST_TIME_MESSAGE];
        }
    } else if ([keyPath isEqual:@"playlists"]) {
        // For custom playlists reload entire cell
        // Must create index path arrays for old and new playlists. Delete old, add new.
        NSArray *playlists = [UserDataManager sharedInstance].playlists;
        NSArray *oldPlaylists = change[NSKeyValueChangeOldKey] == [NSNull null] ? nil : change[NSKeyValueChangeOldKey];
        NSMutableArray *oldIndexPaths = [NSMutableArray arrayWithCapacity:oldPlaylists.count];
        [oldPlaylists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [oldIndexPaths addObject:[NSIndexPath indexPathForRow:3+idx inSection:0]];
        }];
        NSMutableArray *newIndexPaths = [NSMutableArray arrayWithCapacity:playlists.count];
        [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [newIndexPaths addObject:[NSIndexPath indexPathForRow:3+idx inSection:0]];
        }];
        [self.tablePlaylistView beginUpdates]; // required for batch tableview updates
        if (oldIndexPaths.count > 0) {
            [self.tablePlaylistView deleteRowsAtIndexPaths:oldIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
        if (newIndexPaths.count > 0) {
            [self.tablePlaylistView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tablePlaylistView endUpdates];
    }

    //stop showing loading indicator
    if (row >= 0) {
        PlaylistTableViewCell *cell = (PlaylistTableViewCell *)[self.tablePlaylistView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        [cell.activityIndicator stopAnimating];
        cell.songCountLabel.hidden = NO;
    }
    
}


#pragma mark - MenuPopOverView Delegate

- (void)menu:(MenuPopOverView *)menu didSelectItemAtRow:(NSUInteger)row
{
    [menu setHidden:YES];
    switch (row) {
        case menuItemLog: {
            //log on
            MenuItemModel *menuItem = [menu.dataSource objectAtIndex:menuItemLog];
            if ([menuItem.title isEqualToString:LOGON]) {
                // [TestFlight passCheckpoint:@"Selected SignIn from menu"];
                [[SoundCloudAPIManager sharedInstance] login];
                
            } else {
                // logoff
                // [TestFlight passCheckpoint:@"Selected SignOut from menu"];
                [self isLoadingData:YES];
                [SCSoundCloud removeAccess];
                [self didLogOffNotification:nil];
            }
            
            break;
        }
        case 1:
            // [TestFlight passCheckpoint:@"Selected Info from menu"];
            [self showInfoPanel];
            break;
            
        case 2:
            // [TestFlight openFeedbackView];
            break;
            
        default:
            break;
    }
}


// Lazy loader for menu pop over
- (MenuPopOverView *)menu
{
    if (!_menu) {
        _menu = [[[NSBundle mainBundle] loadNibNamed:@"MenuPopOverView" owner:nil options:nil] objectAtIndex:0];
        _menu.frame = CGRectMake(self.view.frame.size.width - _menu.frame.size.width - 6,
                                 63,
                                 _menu.frame.size.width,
                                 _menu.frame.size.height);
        _menu.delegate = self;
        
        //create datasource
        MenuItemModel *menuItem1 = [[MenuItemModel alloc] init];
        menuItem1.title = LOGON;
        menuItem1.iconImage = [UIImage imageNamed:@"menuSignInButton"];
        //menuItem1.iconImageHighlighted = [UIImage imageNamed:@"menuShuffleButtonPress"];
        
        MenuItemModel *menuItem2 = [[MenuItemModel alloc] init];
        menuItem2.title = @"Info";
        menuItem2.iconImage = [UIImage imageNamed:@"menuInfoButton"];
        //menuItem1.iconImageHighlighted = [UIImage imageNamed:@"menuShuffleButtonPress"];
        
        // Disable for Production
        /*MenuItemModel *menuItem3 = [[[MenuItemModel alloc] init] autorelease];
        menuItem3.title = @"Give Feedback";
        menuItem3.iconImage = [UIImage imageNamed:@"menuLikeButtonInactive"];*/
        
        NSMutableArray *menuList = [NSMutableArray arrayWithObjects:menuItem1, menuItem2, /*menuItem3,*/ nil];
        _menu.dataSource = menuList;
        [_menu setHidden:YES];
        
        [self.view addSubview:_menu];
    }
    return _menu;
}

#pragma mark - AdBannerDelegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!CGRectIntersectsRect(banner.frame, self.view.frame)) {
        //animate banner up
        [UIView animateWithDuration:0.33f animations:^{
            self.adBanner.frame = CGRectOffset(self.adBanner.frame, 0, -self.adBanner.frame.size.height);
        }];
    }
    //NSLog(@"Ad Loaded");
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    // [TestFlight passCheckpoint:@"Ad clicked"];
    
    //pause music
    if (self.activePlaylistViewController) {
        [[SCSPlayer sharedInstance] pause];
    }
    return YES;
}

// This message is sent when a modal action has completed and control is returned to the application.
// Games, media playback, and other activities that were paused in response to the beginning
// of the action should resume at this point.
- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    if (self.activePlaylistViewController) {
        //[[SCSPlayer sharedInstance] play];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (CGRectIntersectsRect(banner.frame, self.view.frame)) {
        //animate banner down
        [UIView animateWithDuration:0.33f animations:^{
            CGRect frame = self.adBanner.frame;
            self.adBanner.frame = CGRectMake(0, self.view.frame.size.height, frame.size.width, frame.size.height);
        }];
    }
    //NSLog(@"Ad Failed and animated out");
}
//*/

#pragma mark - SoundCloudManager Delegate


// When all tracks have been recieved, push playlistVC onto stack
- (void)tracksRecieved:(NSArray *)tracks didCompleteAllRequests:(BOOL)isComplete;
{
    //NSArray *tracks =[notification.userInfo objectForKey:@"tracks"];
    [self.trackBuffer addObjectsFromArray:tracks];
    //float progress = self.trackBuffer.count / self.playlistSize;
    //[self.trackProgressView setProgress:progress animated:NO];
    //NSString *message = [NSString stringWithFormat:@"%d/%d tracks received", self.trackBuffer.count, self.playlistSize];
    //NSLog(message);
    
    //Once all track have been received, push them to playlistVC
    //BOOL vcLoaded = self.activePlaylistViewController.isViewLoaded;
    if (isComplete) {
        [self.navigationController pushViewController:self.activePlaylistViewController animated:YES];
        [self.activePlaylistViewController addTracksToPlaylist:self.trackBuffer];
        [self isLoadingData:NO];
        [self.trackBuffer removeAllObjects];
    }
}

- (void)requestDidTimeout:(NSString *)requestIdentifier
{
    //if we have enough tracks we can continue with playlist
    if (self.trackBuffer.count > 0 && self.navigationController.topViewController == self) {
        [self.activePlaylistViewController addTracksToPlaylist:self.trackBuffer];
        [self.navigationController pushViewController:self.activePlaylistViewController animated:YES];
        [self.trackBuffer removeAllObjects];
    } else {
        // Otherwise stop request
        [self.tablePlaylistView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.activePlaylistViewController = nil;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Timeout" message:@"Please try again." cancelButtonItem:[RIButtonItem itemWithLabel:@"OK"] otherButtonItems: nil];
        [alert show];
    }
    [self isLoadingData:NO];
}


#pragma mark - TableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"playlistcell";
    
    //if (indexPath.row < [UserDataManager sharedInstance].playlists.count + 3) {
        PlaylistTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"PlaylistTableViewCell" owner:nil options:nil] objectAtIndex:0];
            NSArray *fontArray = [UIFont fontNamesForFamilyName:@"Quicksand"];
            cell.playlistLabel.font = [UIFont fontWithName:[fontArray objectAtIndex:2] size:17];
            cell.songCountLabel.font  = [UIFont fontWithName:[fontArray objectAtIndex:2] size:17];
            [cell setBackgroundImageForIndexPath:indexPath];
        }
        
        //Load in user data
        UserDataManager *userManager = [UserDataManager sharedInstance];
        
        // Configure the cell
        switch (indexPath.row) {
            case 0:
                cell.playlistLabel.text = @"Band Tracks";
                cell.songCountLabel.text = [NSString stringWithFormat:@"%d", userManager.bandTracksCount];
                self.bandTracksCountLabel = cell.songCountLabel;
                break;
            case 1:
                cell.playlistLabel.text = @"Band Favorites";
                cell.songCountLabel.text = [NSString stringWithFormat:@"%d", userManager.bandFavoritesCount];
                self.bandFavoriteTracksCountLabel = cell.songCountLabel;
                break;
            case 2:
                cell.playlistLabel.text = @"Your Favorites";
                cell.songCountLabel.text = [NSString stringWithFormat:@"%d", userManager.favoritesCount];
                self.favoriteTracksCountLabel = cell.songCountLabel;
                break;
            default: {
                //custom playlist cells
                PlaylistModel *playlist = [UserDataManager sharedInstance].playlists[indexPath.row - 3];
                cell.playlistLabel.text = playlist.title;
                cell.songCountLabel.text = [playlist.trackCount stringValue];
                cell.songCountLabel.hidden = NO;
                break;
            }
        }
        
        if (indexPath.row == 0) {
            cell.activeIndicator.highlighted = YES;
        }
    
        return cell;

    /*} else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        UIImageView *bkgnd = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"homeAddPlaylist"]];
        bkgnd.frame =  CGRectMake((320/2 - 213/2), -2, 213, 60);
        [cell.contentView addSubview:bkgnd];
        
        return  cell;
    }*/
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // default 3 + any custom playlists
    return 3 + [UserDataManager sharedInstance].playlists.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 98.0f;
    /*if (indexPath.row < [UserDataManager sharedInstance].playlists.count + 3) {
        return 98.0f; //playlist cell
    } else {
        return 60.0f; //add playlist cell (not currently implemented)
    }*/
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    PlaylistTableViewCell *cell = (PlaylistTableViewCell *)[self.tablePlaylistView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    // If cell has finished loading...
    if (!cell.activityIndicator.isAnimating) {
        NSString *playlistType = nil;
        int trackCount = 0;
        
        switch (indexPath.row) {
            case 0:
                playlistType = BAND_TRACKS;
                trackCount = [[UserDataManager sharedInstance] bandTracksCount];
                break;
            case 1:
                playlistType = BAND_FAVORITES;
                trackCount = [[UserDataManager sharedInstance] bandTracksCount];
                break;
            case 2:
                playlistType = FAVORITES;
                trackCount = [[UserDataManager sharedInstance] favoritesCount];
                break;
            default: {
                int playlistIndex = (int)indexPath.row-3;
                if (playlistIndex < [UserDataManager sharedInstance].playlists.count) { // if we actually have playlist at index 0 or higher
                    PlaylistModel *playlist = [UserDataManager sharedInstance].playlists[playlistIndex];
                    playlistType = playlist.title;
                    trackCount = [playlist.trackCount intValue];
                }
                break;
            }
                
        }
        
        //if user is not authenticated
        if (![SoundCloudAPIManager isUserAuthenticated]) {
            // Login
            [[SoundCloudAPIManager sharedInstance] login];
            
            /*
            RIButtonItem *okBtn = [RIButtonItem itemWithLabel:@"OK"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Signed In" message:@"You must sign in from the menu first." cancelButtonItem:okBtn otherButtonItems: nil];
            [alert show];
            [alert release];
             */
            
        } else if (trackCount <= 0) {
            RIButtonItem *okBtn = [RIButtonItem itemWithLabel:@"OK"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Open Playlist" message:@"This playlist has no songs/sounds in it. Use soundcloud.com and the SoundCloud app to follow more artists, and favorite their tracks!" cancelButtonItem:okBtn otherButtonItems: nil];
            [alert show];
            
        } else if(playlistType) {
            
            //create new buffer to store tracks and load playlist
            self.playlistSize = MIN(trackCount, 100); //this supports playists up to 100 songs
            self.trackBuffer =  [NSMutableArray arrayWithCapacity:self.playlistSize];
            
            // Lazy load the active playlist. Reuse this for each new playlist.
            if (!self.activePlaylistViewController) {
                self.activePlaylistViewController = [[PlaylistViewController alloc]
                                                      initWithNibName:@"PlaylistViewController" bundle:nil];
            }
            
            //If the previously selected playist is the same then push it back on stack
            if ([self.activePlaylistViewController.playlistType isEqualToString:playlistType]) {
                [self.navigationController pushViewController:self.activePlaylistViewController animated:YES];
            } else {
                // Otherwise begin request for playlist data
                [self isLoadingData:YES];
                //[TestFlight passCheckpoint:[NSString stringWithFormat:@"Selected new playlist: %@", playlistType]];
                
                [self.activePlaylistViewController clearPlaylist];
                self.activePlaylistViewController.title = playlistType;
                self.activePlaylistViewController.playlistType = playlistType;
                
                // Request tracks. distinguish between standard 3 and custom playlists
                [[SoundCloudAPIManager sharedInstance] requestPlaylistType:playlistType delegate:self];
            }
        }
    }
}



#pragma mark - IBActions

- (void)isLoadingData:(BOOL)isLoading
{
    if (isLoading) {
        self.loadingPanel.hidden = NO;
        //self.loadingPanel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.33f];
        [self.loadingIndicator startAnimating];
    } else {
        self.loadingPanel.hidden = YES;
        //self.loadingPanel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        [self.loadingIndicator stopAnimating];
    }
}

// Called when the navigation controller shows a new top view controller via a push, pop or setting of the view controller stack.
/*- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self) {
        self.titleLabel.hidden = NO;
    } else {
        self.titleLabel.hidden = YES;
    }
}*/

- (void)didPressSettingsBtn:(id)sender
{
    [self.menu setHidden: !self.menu.isHidden];
}

- (void)didLogin {
    [self didLogOnNotification:nil];
}

- (void)didLogOnNotification:(NSNotification *)notification
{
    //change Logon to Logoff
    MenuItemModel *menuItem = [self.menu.dataSource objectAtIndex:menuItemLog];
    menuItem.title = LOGOFF;
    menuItem.iconImage = [UIImage imageNamed:@"menuSignOutButton"];
    [self.menu reloadMenuItems];
}

- (void)didLogOffNotification:(NSNotification *)notification
{
    
    //change Logoff to Logon
    MenuItemModel *menuItem = [self.menu.dataSource objectAtIndex:menuItemLog];
    menuItem.title = LOGON;
    menuItem.iconImage = [UIImage imageNamed:@"menuSignInButton"];
    [self.menu reloadMenuItems];
    
    //clear playlist
    [self.activePlaylistViewController clearPlaylist];
    [self.tablePlaylistView reloadData];
    [[UserDataManager sharedInstance] clearAllData];
    
    [self isLoadingData:NO];
}



#pragma mark - InfoPanel

- (InfoPanelView *)infoPanel
{
    if (!_infoPanel) {
        _infoPanel = [[[NSBundle mainBundle] loadNibNamed:@"InfoPanelView" owner:nil options:nil] objectAtIndex:0];
        _infoPanel.frame = CGRectMake(0, 460.0f, self.infoPanel.frame.size.width, 480.0f);
        [_infoPanel.closeButton addTarget:self action:@selector(dismissInfoPanel) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_infoPanel];
        
        MeModel *meInfo = [[UserDataManager sharedInstance] meInfo];
        if ([meInfo username]) {
            _infoPanel.title.text = [NSString stringWithFormat:@"Welcome %@", meInfo.username];
        } else {
            _infoPanel.title.text = @"Welcome";
        }
        
        UIView *message = [[[NSBundle mainBundle] loadNibNamed:@"WelcomeTextView" owner:nil options:nil] objectAtIndex:0];
        [_infoPanel.contentView addSubview:message];
    }
    return _infoPanel;
}

- (void)showInfoPanel
{
    [UIView animateWithDuration:0.5f animations:^{
        float center = (self.view.frame.size.height / 2) + 20.0f;
        self.infoPanel.center = CGPointMake(self.infoPanel.center.x, center);
    }];
}

- (void)dismissInfoPanel
{
    [UIView animateWithDuration:0.5f animations:^{
        float height = [[UIScreen mainScreen] bounds].size.height;
        self.infoPanel.frame = CGRectOffset(self.infoPanel.frame, 0, height);
    }];
}

- (void)startRefreshIndicators
{
    if ([SoundCloudAPIManager isUserAuthenticated]) {
        //start activity indicators on cells since we are still loading in data
        for (int i = 0; i < [self.tablePlaylistView numberOfRowsInSection:0]; i++) {
            PlaylistTableViewCell *cell = (PlaylistTableViewCell *)[self.tablePlaylistView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            [cell.activityIndicator startAnimating];
            cell.songCountLabel.hidden = YES;
        }
    }
}

#pragma mark - Application Lifecycle Notification

// Cancel requests if user exits before request is complete
- (void)willResignActive:(NSNotification *)notif
{
    if (!self.loadingPanel.isHidden) {
        [self isLoadingData:NO];
        [[SoundCloudAPIManager sharedInstance] cancelAllRequests];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //create iAd
    self.adBanner = [[ADBannerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, 0, 0)];
    self.adBanner.delegate = self;
    self.adBanner.backgroundColor = [UIColor clearColor];
    self.adBanner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.adBanner];
    
    //customize table
    self.tablePlaylistView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 20.0f)];
    self.tablePlaylistView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //Add pull to refresh handler
    __weak typeof(self) weakSelf = self;
    [self.tablePlaylistView addPullToRefreshWithActionHandler:^{
        [weakSelf.tablePlaylistView.pullToRefreshView stopAnimating];
        
        //only refresh if user is authenticated
        if ([SoundCloudAPIManager isUserAuthenticated]) {
            [weakSelf startRefreshIndicators];
            [[SoundCloudAPIManager sharedInstance] requestMeInfo];
        }
    }];
    UIColor *color = [UIColor colorWithRed:74.0f/255.0f green:139.0f/255.0f blue:188.0f/255.0f alpha:1.0f];
    UIColor *shadowColor =  [UIColor colorWithWhite:0 alpha:0.17f];
    self.tablePlaylistView.pullToRefreshView.arrowColor =  [[UIColor alloc]initWithRed: 0.2 green: 0.5 blue: 0.7 alpha: 1 ];
    self.tablePlaylistView.pullToRefreshView.textColor = color;
    self.tablePlaylistView.pullToRefreshView.titleLabel.shadowColor = shadowColor;
    self.tablePlaylistView.pullToRefreshView.titleLabel.shadowOffset = CGSizeMake(1, 1);
    
        
    //customize navigationBar
    self.navigationController.navigationBarHidden = NO;
    //UIImage *bgImage = [[UIImage imageNamed:@"navBar7.png"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
    
    //[[UINavigationBar appearance] setBackgroundImage:bgImage forBarPosition:UIBarPositionTop barMetrics:UIBarMetricsDefault];
    UIFont *titleFont = [UIFont fontWithName:[[UIFont fontNamesForFamilyName:@"Quicksand"] objectAtIndex:2] size:25.0f];
    NSShadow *txtshadow = [[NSShadow alloc] init];
    [txtshadow setShadowColor:[UIColor clearColor]];
    [txtshadow setShadowOffset:CGSizeMake(0.0f, 1.0f)];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor orangeTitleColor], NSForegroundColorAttributeName,
                                                          titleFont, NSFontAttributeName,
                                                          txtshadow, NSShadowAttributeName,
                                                          nil]];
    //[[UINavigationBar appearance] setTitleVerticalPositionAdjustment:4.0f forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationItem.hidesBackButton = YES;
    self.titleLabel = [[[NSBundle mainBundle] loadNibNamed:@"TitleView" owner:nil options:nil] objectAtIndex:0];
    self.navigationItem.titleView = self.titleLabel;
    
    //create settings button
    UIButton *settingsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    [settingsBtn addTarget:self action:@selector(didPressSettingsBtn:) forControlEvents:UIControlEventTouchUpInside];
    [settingsBtn setImage:[UIImage imageNamed:@"navSettingsButton"] forState:UIControlStateNormal];
    [settingsBtn setImage:[UIImage imageNamed:@"navSettingsButtonPress"] forState:UIControlEventTouchDown];
    UIBarButtonItem *settingsBtnItem = [[UIBarButtonItem alloc] initWithCustomView:settingsBtn];
    self.navigationItem.rightBarButtonItem = settingsBtnItem;
    
    /*if (userManager.meInfo != nil) {
        self.nameLabel.text = [NSString stringWithFormat:@"Welcome %@,", userManager.meInfo.username];
    }*/
    
    //Add observers to count data
    UserDataManager *userManager = [UserDataManager sharedInstance];
    [userManager addObserver:self forKeyPath:@"meInfo" options:NSKeyValueObservingOptionNew context:nil];
    [userManager addObserver:self forKeyPath:@"favoritesCount" options:NSKeyValueObservingOptionNew context:nil];
    [userManager addObserver:self forKeyPath:@"bandTracksCount" options:NSKeyValueObservingOptionNew context:nil];
    [userManager addObserver:self forKeyPath:@"bandFavoritesCount" options:NSKeyValueObservingOptionNew context:nil];
    [userManager addObserver:self forKeyPath:@"playlists" options:NSKeyValueObservingOptionOld context:nil];
    
    //round corners
    self.loadingDarkRect.layer.cornerRadius = 12.0f;
    self.loadingDarkRect.layer.shadowRadius = 2.0f;
    self.loadingDarkRect.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.loadingDarkRect.layer.shadowOpacity = 0.5f;
    self.loadingDarkRect.layer.shadowOffset = CGSizeMake(1, 2);
    
    // Parallax to loading indicator
    UIInterpolatingMotionEffect *loadingHorizontalMotion = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    loadingHorizontalMotion.minimumRelativeValue = @(-30);
    loadingHorizontalMotion.maximumRelativeValue = @(30);
    UIInterpolatingMotionEffect *loadingVerticalMotion = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    loadingVerticalMotion.minimumRelativeValue = @(-35);
    loadingVerticalMotion.maximumRelativeValue = @(35);
    [self.loadingDarkRect addMotionEffect:loadingHorizontalMotion];
    [self.loadingDarkRect addMotionEffect:loadingVerticalMotion];
    
    //add spacing to bottom of tableview to offset adbanner
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 60.0f)];
    [self.tablePlaylistView setTableFooterView:footer];
    
    //register for track recieved notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tracksFromPlaylistReceived:) name:TRACKS_RECIEVED_NOTIFICATION object:nil];
    
    //register for logoff and logon notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogOffNotification:) name:@"logoff" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogOnNotification:) name:@"logon" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    
}

- (void)viewDidUnload
{
    [self setNameLabel:nil];
    [self setBandTracksCountLabel:nil];
    [self setBandFavoriteTracksCountLabel:nil];
    [self setFavoriteTracksCountLabel:nil];
    [self setLoadingPanel:nil];
    [self setLoadingIndicator:nil];
    [self setTablePlaylistView:nil];
    [self setTitleLabel:nil];
    [self setLoadingDarkRect:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Refresh track count data
    
    // [TestFlight passCheckpoint:@"Navigated to HomeViewController"];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


     
@end
