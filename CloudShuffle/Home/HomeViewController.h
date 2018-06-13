//
//  ViewController.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 12/31/11.
//  Copyright (c) 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SoundCloudAPIManager.h"
#import "MenuPopOverView.h"
#import "InfoPanelView.h"
#import <iAd/iAd.h>

#define LOGOFF @"Sign Out"
#define LOGON @"Sign In"

@class PlaylistViewController;

@interface HomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ADBannerViewDelegate, MenuPopOverViewDelegate, SoundCloudAPIManagerDelegate> {
    MenuPopOverView *menu_;
}

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *bandTracksCountLabel;
@property (strong, nonatomic) UILabel *bandFavoriteTracksCountLabel;
@property (strong, nonatomic) UILabel *favoriteTracksCountLabel;
@property (weak, nonatomic) IBOutlet UIView *loadingPanel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIView *loadingDarkRect;
@property (strong, nonatomic) PlaylistViewController *activePlaylistViewController;
@property (weak, nonatomic) IBOutlet UITableView *tablePlaylistView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) MenuPopOverView *menu;
@property (strong, nonatomic) InfoPanelView *infoPanel;
//@property (retain, nonatomic) IBOutlet UIProgressView *trackProgressView;
@property (strong) NSMutableArray *trackBuffer;
@property (assign, nonatomic) int playlistSize;
@property (nonatomic, strong) ADBannerView *adBanner;

- (void)isLoadingData:(BOOL)isLoading;
- (void)startRefreshIndicators;
- (void)didLogin;

@end
