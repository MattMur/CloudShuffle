//
//  PlaylistViewController.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/2/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeModel.h"
#import "TrackModel.h"
#import "ImageDownloader.h"
#import "SCSPlayer.h"
#import "MenuPopOverView.h"

typedef enum {
    TrackStatePlay,
    TrackStatePause
} TrackState;


@interface PlaylistViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, SCSPlayerDelegate, MenuPopOverViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *WaveFormContainer;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIView *trackPanel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UITableView *tracksTableView;
@property (weak, nonatomic) IBOutlet UILabel *playPositionLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bufferImageView;
@property (weak, nonatomic) IBOutlet UIView *trackInfoPanel;
@property (weak, nonatomic) IBOutlet UIImageView *trackProgressRemainImage;
@property (weak, nonatomic) IBOutlet UIImageView *trackProgressCompleteImage;
@property (strong, nonatomic) UIActivityIndicatorView *trackArtworkActivity;
@property (strong, nonatomic) UIActivityIndicatorView *bufferActivity;
@property (weak, nonatomic) IBOutlet UIView *loadingPanel;
@property (weak, nonatomic) IBOutlet UIView *loadingDarkRect;

@property (strong, nonatomic) MenuPopOverView *menu;
@property (strong, nonatomic) NSArray *menuDatasource;
@property (strong, nonatomic) UIImageView *trackArtworkView;
@property (weak, nonatomic) SCSPlayer *player;
@property (strong, nonatomic) NSString *playlistType;
@property (strong) NSTimer *trackTimer;
@property (strong) NSMutableArray *tracksArray;  //datasource for tableView

//Image downloader for track art in tableView
@property (strong, nonatomic) NSMutableDictionary *imageDownloadsInProgress;

//Manage playlist
- (void)addTracksToPlaylist:(NSArray *)tracks;
- (void)setTrackProgressPosition:(NSUInteger)position;
- (void)clearPlaylist;
- (void)toggleTrackState:(TrackState)state;
- (void)shufflePlaylist;

//Shows the infoPanel but only for a duration. Will fail if infoPanel is being animated when call is made.
- (void)showTrackInfoPanelforDuration:(float)seconds;

//Will toggle the infoPanel into view if true, out of view if false
- (void)showTrackInfoPanel:(BOOL)isDisplayed;


- (IBAction)previousButtonPress:(id)sender;
- (IBAction)playButtonPress:(id)sender;
- (IBAction)nextButtonPress:(id)sender;



@end
