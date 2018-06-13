//
//  PlaylistViewController.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/2/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PlaylistViewController.h"
#import "SoundCloudAPIManager.h"
#import "TrackTableViewCell.h"
#import "SCSUtilities.h"
#import "MenuItemModel.h"
#import "Reachability.h"
//#import "TestFlight.h"
#import "UIAlertView+Blocks.h"
#import <MediaPlayer/MediaPlayer.h>


#define TRACKPANEL_HEIGHT_MIN 103.0f
#define TRACKPANEL_HEIGHT_MAX 460.0f
#define MAX_DEPTH 30.0f

typedef enum {
    menuItemShuffle = 0,
    menuItemLikeTrack,
    menuItemShare
} MenuItemType;

typedef void (^ViewLoadCompletion)();


@interface PlaylistViewController () <SoundCloudAPIManagerDelegate> {
    float pre_offset;
    NSTimeInterval pre_time;
    CGRect start_table_frame;
    CGRect start_panel_frame;
    float velocity;
    BOOL isSeeking; //used to stop play position from updating when seeking via pan gesture
}
@property (atomic, assign) BOOL isShowingInfoPanel;
@property (atomic, assign) BOOL isAnimatingInfoPanel;
@property (nonatomic) NSOperationQueue *viewLoadQueue;
@property (nonatomic, retain) NSMutableArray *tracksBuffer;

- (void)toggleBufferImageAnimation;

@end

@implementation PlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        pre_offset = 0;
        pre_time = 0;
        isSeeking = NO;
        self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
        
        //Start Player
        self.tracksArray = [NSMutableArray array];
        self.player = [SCSPlayer sharedInstance];
        self.player.delegate = self;
        self.player.playlist = self.tracksArray;
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                selector:@selector(addAdditionalTracks:)
                                                    name:TRACKS_RECIEVED_NOTIFICATION
                                                  object:nil];

        self.viewLoadQueue = [[NSOperationQueue alloc] init];
        [self.viewLoadQueue setSuspended:YES];
    }
    return self;
}



#pragma mark - Menu PopOver Delegate

- (void)menu:(MenuPopOverView *)menuView didSelectItemAtRow:(NSUInteger)row 
{
    [menuView setHidden:YES];
    switch (row) {
        case menuItemShuffle:
            // [TestFlight passCheckpoint:@"Selected Shuffle from menu"];
            [self shufflePlaylist];
            break;
        case menuItemLikeTrack: {
            // [TestFlight passCheckpoint:@"Selected Like/Unlike from menu"];
            TrackModel *track = self.player.selectedTrack;
            if (track.is_user_favorite) {
                //Unfavorite track
                MenuItemModel *menuItem2 = [self.menuDatasource objectAtIndex:menuItemLikeTrack];
                menuItem2.title = @"Like Track";
                [self.menu reloadMenuItems];

                track.is_user_favorite = NO;
                [[SoundCloudAPIManager sharedInstance] removeFavoriteTrack:track];
                
            } else {
                //Favorite track
                MenuItemModel *menuItem2 = [self.menuDatasource objectAtIndex:menuItemLikeTrack];
                menuItem2.title = @"Unlike Track";
                [self.menu reloadMenuItems];
                
                track.is_user_favorite = YES;
                [[SoundCloudAPIManager sharedInstance] addFavoriteTrack:track];
            }
            
            break;
        }
        case menuItemShare: {
            TrackModel *track = self.player.selectedTrack;
            
            NSString *post = [NSString stringWithFormat:@"Check this out - %@ %@", track.artist.username, track.title];
            NSArray *items = @[post, [NSURL URLWithString:track.permalink_url]];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
            [self presentViewController:activityVC animated:YES completion:nil];
            break;
        }
        case 3: {
            break;
        }
            
        case 4: {
            break;
        }
        default:
            break;
    }
}



#pragma mark - SCSPlayer Delegate


- (void)trackChangedToIndex:(int)index
{
    TrackModel *track = [self.tracksArray objectAtIndex:index];
    
    //start image download for track if we don't already have it
    //if (!self.trackArtworkView.image) {
    self.trackArtworkView.image = nil;
    [self.trackArtworkActivity startAnimating];
    [ImageDownloader startDownloadForTrack:track withImageSize:IMAGE_SIZE_ORIGINAL completion:^(UIImage *img) {
        
        
        if (img) {
            self.trackArtworkView.image = img;
            [self.trackArtworkActivity stopAnimating];
            
            //update lockScreen and other media
            MPMediaItemArtwork *trackArtworkMedia = [[MPMediaItemArtwork alloc] initWithImage:img];
            NSDictionary *mediaInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
            [mediaInfo setValue:trackArtworkMedia forKey:MPMediaItemPropertyArtwork];
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
        }
    }];
    
    
    //set media lock screen
    NSArray *keys = [NSArray arrayWithObjects:
                     MPMediaItemPropertyAlbumTitle,
                     MPMediaItemPropertyAlbumTrackNumber,
                     MPMediaItemPropertyArtist,
                     MPMediaItemPropertyTitle,
                     MPMediaItemPropertyPlaybackDuration, nil];
    NSArray *values = [NSArray arrayWithObjects:
                       self.playlistType,
                       [NSNumber numberWithInt:index],
                       track.artist.username,
                       track.title,
                       [NSNumber numberWithInt:([track.duration unsignedIntValue] / 1000) % 60],
                       nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
    
    
    // Do these action items only if the application is in the foreground and active
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        
        [self toggleBufferImageAnimation];
        
        //Set Labels and images
        
        self.songLabel.text = track.title;
        self.artistLabel.text = track.artist.username;
        
        //show track info panel
        [self showTrackInfoPanelforDuration:4.0f];
        
        //highlight favorite
        if (track.is_user_favorite) {
            MenuItemModel *menuItem2 = [self.menuDatasource objectAtIndex:menuItemLikeTrack];
            menuItem2.iconImage = [UIImage imageNamed:@"menuLikeButton"];
            menuItem2.iconImageHighlighted = [UIImage imageNamed:@"menuLikeButtonPress"];
            menuItem2.title = @"Unlike Track";
            [self.menu reloadMenuItems];
            
        } else {
            MenuItemModel *menuItem2 = [self.menuDatasource objectAtIndex:menuItemLikeTrack];
            menuItem2.iconImage = [UIImage imageNamed:@"menuLikeButtonInactive"];
            menuItem2.iconImageHighlighted = [UIImage imageNamed:@"menuLikeButtonInactivePress"];
            menuItem2.title = @"Like Track";
            [self.menu reloadMenuItems];
        }
        
        
        //select row if it hasn't already been selected
        if (self.tracksArray.count > 0) {
            [[self tracksTableView] selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]
                                                animated:YES
                                          scrollPosition:UITableViewScrollPositionNone];
        }
        
        
        
        //reset timer and labels
        [self.trackTimer invalidate];
        self.trackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(updatePlayPosition:)
                                                         userInfo:nil
                                                          repeats:YES];
        NSString *timeStr = [SCSUtilities timeFormatted:[track.duration unsignedIntValue]];
        self.durationLabel.text = timeStr;
        self.playPositionLabel.text = @"0.00";
        [self setTrackProgressPosition:0];
        
    }
}

- (void)setObserversOnStream:(SCAudioStream *)stream
{
    [stream addObserver:self forKeyPath:@"bufferState" options:NSKeyValueObservingOptionNew context:nil];
    [stream addObserver:self forKeyPath:@"playState" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserversOnStream:(SCAudioStream *)stream
{
    [stream removeObserver:self forKeyPath:@"bufferState"];
    [stream removeObserver:self forKeyPath:@"playState"];
}

#pragma mark - Playlist Functions

- (void)addTracksToPlaylist:(NSArray *)tracks {

    if ([tracks count] > 0) {
        //shuffle tracks
        tracks = [SCSUtilities shuffleArray:tracks];
        
        // Are we starting with clean slate or adding to existing playlist?
        BOOL newPlaylist = self.tracksArray.count == 0 ? YES : NO;
        
        // Add indexPath for each track starting at current number of tracks
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:tracks.count];
        int curr_count = (int)[self.tracksArray count];
        for (int i = 0; i < tracks.count; i++) {
            [paths addObject:[NSIndexPath indexPathForRow:curr_count + i inSection:0]];
        }
        [self.tracksArray addObjectsFromArray:tracks];
        [self.tracksTableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
        
        // Important that this only gets run if view is loaded. Sets new playlist and selects the first track.
        __weak typeof(self) weakself = self;
        [self.viewLoadQueue addOperationWithBlock:^{
            // perform on main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (newPlaylist) {
                    [weakself.player setNewPlaylist:self.tracksArray];
                }
            });
        }];
    }
}

- (void)addAdditionalTracks: (NSNotification *)notification
{
    NSArray *tracks =[notification.userInfo objectForKey:@"tracks"];
    [self addTracksToPlaylist:tracks];
}

- (void)shufflePlaylist
{
    [self.player pause];
    self.loadingPanel.hidden = NO;
    [self.tracksArray removeAllObjects];
    [self.tracksTableView reloadData];
    [[SoundCloudAPIManager sharedInstance] requestPlaylistType:self.playlistType delegate:self];
}


//Clear data, cancel requests and notifications
- (void)clearPlaylist {
    [self.player pause];
    [self.tracksArray removeAllObjects];
    [self.tracksTableView reloadData];
    [[SoundCloudAPIManager sharedInstance] cancelAllRequests];
    [self.trackTimer invalidate];
    
}

#pragma mark - SCAPIManager Delegate

- (void)tracksRecieved:(NSArray *)tracks didCompleteAllRequests:(BOOL)isComplete
{
    if (!self.tracksBuffer) {
        self.tracksBuffer = [[NSMutableArray alloc] initWithCapacity:100];
    }
    [self.tracksBuffer addObjectsFromArray:tracks];
    
    if (isComplete) {
        [self addTracksToPlaylist:self.tracksBuffer];
        self.loadingPanel.hidden = YES;
        [self.tracksBuffer removeAllObjects];
    }
}

- (void)requestDidTimeout:(NSString *)requestIdentifier
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Timeout" message:@"Please try again." cancelButtonItem:[RIButtonItem itemWithLabel:@"OK"] otherButtonItems: nil];
    [alert show];
    self.loadingPanel.hidden = YES;
    [self.tracksBuffer removeAllObjects];
}

#pragma mark -

- (void)toggleBufferImageAnimation {
    switch (self.player.audioStream.bufferState) {
        case SCAudioStreamBufferState_Buffering:
            //NSLog(@"buffering track");
            //self.playButton.enabled = NO;
            //self.pauseButton.enabled = NO;
            
            [self.bufferActivity startAnimating];
            self.trackProgressRemainImage.image = [UIImage imageNamed:@"trackProgressBeginBuffer"];
            self.trackProgressCompleteImage.image = [UIImage imageNamed:@"trackProgressEndBuffer"];
            break;
        case SCAudioStreamBufferState_NotBuffering:
            //NSLog(@"not buffering");
            //self.playButton.enabled = YES;
            //self.pauseButton.enabled = YES;
            [self.bufferActivity stopAnimating];
            self.trackProgressRemainImage.image = [UIImage imageNamed:@"trackProgressBegin"];
            self.trackProgressCompleteImage.image = [UIImage imageNamed:@"trackProgressEnd"];
            
            break;
            
        default:
            break;
    }

}

#pragma mark - App Notifications

- (void)appDidLeaveForeground:(NSNotification *) notification {
    //[self.player.audioStream removeObserver:self forKeyPath:@"bufferState"];
    //[self.player.audioStream removeObserver:self forKeyPath:@"playState"];
}

- (void)appDidEnterForeground:(NSNotification *) notification {
    //[self.player.audioStream addObserver:self forKeyPath:@"bufferState" options:NSKeyValueObservingOptionNew context:nil];
    //[self.player.audioStream addObserver:self forKeyPath:@"playState" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *iReach = [notification object];
    
    switch (iReach.currentReachabilityStatus) {
        case NotReachable:
            [self.player pause];
            break;
        case ReachableViaWiFi:
            break;
        case ReachableViaWWAN:
            break;
            
        default:
            break;
    }
    
}

- (void)trackDidBecomeUnavailible:(NSNotification *)notification
{
    [self.player nextSong];
    NSLog(@"Track became unavailible");
    // [TestFlight passCheckpoint:@"Stream became unavailible..."];
}

- (void)trackWasInterrupted:(NSNotification *)notification
{
    //NSLog(@"Track was interupted. Lets play some music and see how that goes..");
    [self.player play];
    //[TestFlight passCheckpoint:@"Playback was interrupted..."];
}


#pragma mark - DataSource Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tracksArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MyCell";
    
    TrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = ((TrackTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:@"TrackTableViewCell"
                                                                     owner:nil
                                                                   options:nil]
                                       objectAtIndex:0]);
        
    }
    
    // Configure motion effects and shadow
    if (cell.motionEffects.count == 0) {
        cell.trackImageView.layer.cornerRadius = 5.0f;
        cell.trackImageView.clipsToBounds = YES;
        
        // Add parallax
        /*float depth = 25.0f;
        //float shadowDif = abs(30-depth);
        UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(depth);
        horizontalMotionEffect.maximumRelativeValue = @(-depth);
        [cell addMotionEffect:horizontalMotionEffect];
        
        UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(depth);
        verticalMotionEffect.maximumRelativeValue = @(-depth);
        [cell addMotionEffect:verticalMotionEffect];
         */
        
        //shadow view is needed as separate view because trackArtworkView will clip the shadow
        cell.shadowContainer.layer.cornerRadius = 5.0f;
        cell.shadowContainer.layer.shadowOffset = CGSizeMake(0, 1);
        cell.shadowContainer.layer.shadowOpacity = 0.4f;
        cell.shadowContainer.layer.shadowRadius = 0.01f;
        cell.shadowContainer.layer.shadowColor = [[UIColor blackColor] CGColor];
        
        /*UIInterpolatingMotionEffect *shadowHorizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        shadowHorizontalMotionEffect.minimumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(shadowDif, cell.shadowContainer.layer.shadowOffset.height)];
        shadowHorizontalMotionEffect.maximumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(-shadowDif, cell.shadowContainer.layer.shadowOffset.height)];
        [cell.shadowContainer addMotionEffect:shadowHorizontalMotionEffect];
        UIInterpolatingMotionEffect *shadowVerticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        shadowVerticalMotionEffect.minimumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(cell.shadowContainer.layer.shadowOffset.width, shadowDif)];
        shadowVerticalMotionEffect.maximumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(cell.shadowContainer.layer.shadowOffset.width, -shadowDif)];
        [cell.shadowContainer addMotionEffect:shadowVerticalMotionEffect];*/
    }
    
    // Configure the cell...
    TrackModel *track = [self.tracksArray objectAtIndex:indexPath.row];
    cell.songNameLabel.text = track.title;
    cell.artistNameLabel.text = track.artist.username;
    
    //Load image from memory if availible. Otherwise use ImageDownloader
    if (track.track_image) {
        cell.trackImageView.image = track.track_image;
    } else {
        
        [ImageDownloader startDownloadForTrack:track withImageSize:IMAGE_SIZE_SMALL completion:^(UIImage *img) {
            track.track_image = img;
            cell.trackImageView.image = img;
        }];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.player setNewTrack:indexPath.row];
    [self.player play];
}



#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"bufferState"]) {
        [self toggleBufferImageAnimation];
    } else if ([keyPath isEqual:@"playState"]) {
        
        SCAudioStreamState state = (SCAudioStreamState)[[change objectForKey:NSKeyValueChangeNewKey] intValue];
        
        switch (state) {
            case SCAudioStreamState_Playing:
                [self toggleTrackState:TrackStatePlay];
                //NSLog(@"state: playing");
                break;
                
            case SCAudioStreamState_Paused:
                if (!self.player.isBuffering) { // We only want to show pause if not buffering
                    [self toggleTrackState:TrackStatePause];
                    //NSLog(@"state: paused");
                }
                break;
            case SCAudioStreamState_Initialized:
                //NSLog(@"state: initialized");
                break;
            case SCAudioStreamState_Stopped:
                [self toggleTrackState:TrackStatePause];
                //NSLog(@"state: stopped");
                break;
            default:
                break;
        }
    }
}

#pragma mark - Player Control


- (IBAction)playButtonPress:(id)sender {
    // [TestFlight passCheckpoint:@"Play button press"];
    if (self.player.audioStream.playState == SCAudioStreamState_Playing) {
        [self.player pause];
    } else {
        [self.player play];
    }
    
}

- (IBAction)previousButtonPress:(id)sender {
    // [TestFlight passCheckpoint:@"Previous button press"];
    [self.player previousSong];
}

- (IBAction)nextButtonPress:(id)sender {
    // [TestFlight passCheckpoint:@"Next button press"];
    [self.player nextSong];
    [self.player play];
}


- (void)toggleTrackState:(TrackState)state {
    switch (state) {
        case TrackStatePlay:
            //[self.player play];
            self.playButton.hidden = YES;
            self.pauseButton.hidden = NO;
            break;
        case TrackStatePause:
            //[self.player pause];
            self.playButton.hidden = NO;
            self.pauseButton.hidden = YES;
            break;
            
        default:
            break;
    }
}

- (void)didPressBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didPressSettingsBtn:(id)sender
{
    [self.menu setHidden: !self.menu.isHidden];
}

#pragma mark - Update Timer

//Adjust the width of each image to give the appearance of a sliding progress bar
- (void)setTrackProgressPosition:(NSUInteger)position
{
    self.trackProgressCompleteImage.frame = CGRectMake(0, 0, 
                                                       (float)position, 
                                                       self.trackProgressCompleteImage.frame.size.height);
    self.trackProgressRemainImage.frame = CGRectMake((float)position, 0, 
                                                     self.WaveFormContainer.frame.size.width - position, 
                                                     self.trackProgressRemainImage.frame.size.height);
}

- (void)updatePlayPosition:(NSTimer *)timer
{
    if (!isSeeking && self.tracksArray.count > 0) {
        TrackModel *track = self.player.selectedTrack;
        
        float percentComplete = (float)self.player.audioStream.playPosition
                                    / [track.duration unsignedIntValue];
        NSUInteger newPayPosition = percentComplete * self.WaveFormContainer.frame.size.width;
        
        //When there are less than 7 seconds start the buffer for next song
        NSUInteger timeRemain = [track.duration unsignedIntValue] - self.player.audioStream.playPosition;
        if (timeRemain < 7000) {
            [self.player startBufferNextStream];
        }
        
        //set song progress indicator
        [self setTrackProgressPosition:newPayPosition];
        //self.songProgressView.frame = CGRectMake(0, 0, newPayPosition, self.songProgressView.frame.size.height);
        
        //set track playposition label
        NSString *timeStr = [SCSUtilities timeFormatted:self.player.audioStream.playPosition];
        self.playPositionLabel.text = timeStr;
    }
}


#pragma mark - Handle Gestures

- (void)showTrackInfoPanelforDuration:(float)seconds
{
    if (!self.isShowingInfoPanel) {
        
        //remove any previous animations to prepare for the new ones
        [self.trackInfoPanel.layer removeAllAnimations];
        
        float navbarHeight = 64.0f;
        float distance = self.trackInfoPanel.frame.size.height + navbarHeight;
        
        //show it and then hide it again if neccessary
        self.isShowingInfoPanel = YES;
        [UIView animateWithDuration:0.33f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            self.trackInfoPanel.frame = CGRectOffset(self.trackInfoPanel.frame, 0, distance);
            
        } completion:^(BOOL finished) {
            if (finished && self.isShowingInfoPanel) {
                //after delay animate panel back up
                [UIView animateWithDuration:0.33f delay:seconds options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [UIView setAnimationBeginsFromCurrentState:YES];
                    //self.isAnimatingInfoPanel = YES;
                    self.trackInfoPanel.frame = CGRectMake(0, -90, self.trackInfoPanel.frame.size.width, self.trackInfoPanel.frame.size.height);
                } completion:^(BOOL finished) {
                    self.isShowingInfoPanel = NO;
                    //self.isAnimatingInfoPanel = NO;
                }];
            }
        }];
        
    }
    //NSLog(@"frame(duration): \n%@", NSStringFromCGRect(self.trackInfoPanel.frame));
}

//Set the trackInfoPanel to display or hide
- (void)showTrackInfoPanel:(BOOL)isDisplayed
{
    if (!self.isAnimatingInfoPanel) {
        self.isAnimatingInfoPanel = YES;
        [self.trackInfoPanel.layer removeAllAnimations];
        float navbarHeight = 64.0f;
        float distance = self.trackInfoPanel.frame.size.height + navbarHeight;
        distance = (isDisplayed ? distance : -distance);
        self.isShowingInfoPanel = isDisplayed;
        [UIView animateWithDuration:0.33f animations:^{
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            self.trackInfoPanel.frame = CGRectOffset(self.trackInfoPanel.frame, 0, distance);
        } completion:^(BOOL finished) {
            self.isAnimatingInfoPanel = NO;
        }];
    }
    //NSLog(@"frame(toggle): \n%@", NSStringFromCGRect(self.trackInfoPanel.frame));
    
}


- (void)handleInfoPanelTapGesture:(id)sender
{
    if (self.isShowingInfoPanel) {
        //hide
        [self showTrackInfoPanel:NO];
    } else {
        //show
        [self showTrackInfoPanel:YES];
    }
    
}

- (void)handleTapGesture:(id)sender
{
    UITapGestureRecognizer *gesture = sender;
    TrackModel *track = self.player.selectedTrack;
    
    //Find the millisecond to seek to
    CGPoint tapPoint = [gesture locationInView:self.WaveFormContainer];
    float percentageWidthInContainer = tapPoint.x / self.WaveFormContainer.frame.size.width;
    NSUInteger millisecond = percentageWidthInContainer * [track.duration unsignedIntValue];
    
    //seek to position that was tapped
    BOOL startPlay = (self.player.audioStream.playState == SCAudioStreamState_Playing);
    [self.player seekToMillisecond:millisecond startPlaying:startPlay];
    
    
    //set song progress indicator
    [self setTrackProgressPosition:tapPoint.x];
    
}


- (void)handlePanSeekGesture:(UIPanGestureRecognizer *)gesture
{
    TrackModel *track = self.player.selectedTrack;
    
    //Find the millisecond to seek to
    CGPoint tapPoint = [gesture locationInView:self.WaveFormContainer];
    float percentageWidthInContainer = tapPoint.x / self.WaveFormContainer.frame.size.width;
    NSUInteger millisecond = percentageWidthInContainer * [track.duration unsignedIntValue];
    
    //set track playposition label
    NSString *timeStr = [SCSUtilities timeFormatted:millisecond];
    self.playPositionLabel.text = timeStr;
    //self.playPositionLabelLarge.text = timeStr;
    
    //set song progress indicator
    //self.songProgressView.frame = CGRectMake(0, 0, tapPoint.x, self.songProgressView.frame.size.height);
    [self setTrackProgressPosition:tapPoint.x];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            isSeeking = YES;
            break;
            
        case UIGestureRecognizerStateEnded:
            //seek to position that was tapped
            [self.player seekToMillisecond:millisecond
                              startPlaying:(self.player.audioStream.playState == SCAudioStreamState_Playing)];
            isSeeking = NO;
            break;
            
        default:
            break;
    }
    
}





#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //register for internet reachability status
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reachabilityChanged:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    //self.navigationItem.leftBarButtonItem = backBarBtn;
    [self.navigationController.navigationBar setTintColor:[UIColor orangeTitleColor]];
    
    //create settings button
    UIButton *settingsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 23, 23)];
    [settingsBtn addTarget:self action:@selector(didPressSettingsBtn:) forControlEvents:UIControlEventTouchUpInside];
    [settingsBtn setImage:[UIImage imageNamed:@"navSettingsButton"] forState:UIControlStateNormal];
    [settingsBtn setImage:[UIImage imageNamed:@"navSettingsButtonPress"] forState:UIControlEventTouchDown];
    UIBarButtonItem *settingsBtnItem = [[UIBarButtonItem alloc] initWithCustomView:settingsBtn];
    self.navigationItem.rightBarButtonItem = settingsBtnItem;
    
    // Create menu and datasource for menu
    self.menu = [[[NSBundle mainBundle] loadNibNamed:@"MenuPopOverView" owner:nil options:nil] objectAtIndex:0];
    self.menu.frame = CGRectMake(self.view.frame.size.width - self.menu.frame.size.width - 8,
                                 self.navigationController.navigationBar.frame.size.height+18,
                                 self.menu.frame.size.width,
                                 self.menu.frame.size.height);

    self.menu.delegate = self;
    
    MenuItemModel *menuItem1 = [[MenuItemModel alloc] init];
    menuItem1.title = @"Reshuffle";
    //menuItem1.iconImage = [UIImage imageNamed:@"menuShuffleButton"];
    //menuItem1.iconImageHighlighted = [UIImage imageNamed:@"menuShuffleButtonPress"];
    
    MenuItemModel *menuItem2 = [[MenuItemModel alloc] init];
    menuItem2.title = @"Like Track";
    //menuItem2.iconImage = [UIImage imageNamed:@"menuLikeButtonInactive"];
    //menuItem2.iconImageHighlighted = [UIImage imageNamed:@"menuLikeButtonInactivePress"];
    
    MenuItemModel *menuItem3 = [[MenuItemModel alloc] init];
    menuItem3.title = @"Share Track";
    
    self.menuDatasource = @[menuItem1, menuItem2, menuItem3];
    self.menu.dataSource = self.menuDatasource;
    [self.menu setHidden:YES];
    [self.view addSubview:self.menu];
    
    //Create track artwork for table header
    self.trackArtworkView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300.0f, 240.0f)];
    self.trackArtworkView.layer.cornerRadius = 10.0f;
    self.trackArtworkView.layer.masksToBounds = YES;
    self.trackArtworkView.userInteractionEnabled = YES;
    self.trackArtworkView.backgroundColor = [UIColor lightGrayColor];
    UIImageView *shineOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"artworkOverlay"]];
    shineOverlay.opaque = NO;
    shineOverlay.userInteractionEnabled = YES;
    [self.trackArtworkView addSubview:shineOverlay];
    self.trackArtworkActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.trackArtworkActivity.center = self.trackArtworkView.center;
    self.trackArtworkActivity.hidesWhenStopped = YES;
    [self.trackArtworkView addSubview:self.trackArtworkActivity];
    
    // Add parallax to track artwork
    /*int depth = 20;
    //float shadowDif = abs(MAX_DEPTH-depth);
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(depth);
    horizontalMotionEffect.maximumRelativeValue = @(-depth);
    [self.trackArtworkView addMotionEffect:horizontalMotionEffect];
    
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(depth);
    verticalMotionEffect.maximumRelativeValue = @(-depth);
    [self.trackArtworkView addMotionEffect:verticalMotionEffect];
     */
    
    
    //shadow view is needed as separate view because trackArtworkView will clip the shadow
    UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 15.0f, 300.0f, 240.0f)];
    shadowView.layer.cornerRadius = 10.0f;
    shadowView.layer.shadowOffset = CGSizeMake(2, 3);
    shadowView.layer.shadowOpacity = 0.4f;
    shadowView.layer.shadowRadius = .01f;
    shadowView.layer.shadowColor = [[UIColor blackColor] CGColor];
    shadowView.userInteractionEnabled = YES;
    shadowView.opaque = NO;
    [shadowView addSubview:self.trackArtworkView];
    /*UIInterpolatingMotionEffect *shadowHorizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    shadowHorizontalMotionEffect.minimumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(shadowDif, shadowView.layer.shadowOffset.height)];
    shadowHorizontalMotionEffect.maximumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(-shadowDif, shadowView.layer.shadowOffset.height)];
    [shadowView addMotionEffect:shadowHorizontalMotionEffect];
    UIInterpolatingMotionEffect *shadowVerticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    shadowVerticalMotionEffect.minimumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(shadowView.layer.shadowOffset.width, shadowDif)];
    shadowVerticalMotionEffect.maximumRelativeValue = [NSValue valueWithCGSize:CGSizeMake(shadowView.layer.shadowOffset.width, -shadowDif)];
    [shadowView addMotionEffect:shadowVerticalMotionEffect];*/

    //Add to TableView header
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 265)];
    [header addSubview:shadowView];
    //[header addSubview:trackArtworkView];
    
    [self.tracksTableView setTableHeaderView:header];
    
    //add spacing to tableview footer for proper spacing
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 180.0f)];
    [self.tracksTableView setTableFooterView:footer];
    
    //add buffer activity indicator
    self.bufferActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.trackPanel addSubview:self.bufferActivity];
    self.bufferActivity.center = self.playButton.center;
    
    //add tap gesture to infoPanel and NavBar
    UIButton *tapNavButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tapNavButton.frame = CGRectMake(100, 0, 150, 44);
    [tapNavButton addTarget:self action:@selector(handleInfoPanelTapGesture:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.navigationBar addSubview:tapNavButton];
    
    UITapGestureRecognizer *infoPanelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleInfoPanelTapGesture:)];
    UITapGestureRecognizer *artworkTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleInfoPanelTapGesture:)];
    [self.trackInfoPanel addGestureRecognizer:infoPanelTapGesture];
    [self.trackArtworkView addGestureRecognizer:artworkTapGesture];
    
    
    //start gestures
    UIPanGestureRecognizer *seekPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanSeekGesture:)];
    [self.WaveFormContainer addGestureRecognizer:seekPanGesture];
    
    UITapGestureRecognizer *seekTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.WaveFormContainer addGestureRecognizer:seekTapGesture];
    
    //round corners
    self.loadingDarkRect.layer.cornerRadius = 12.0f;
    self.loadingDarkRect.layer.shadowRadius = 2.0f;
    self.loadingDarkRect.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.loadingDarkRect.layer.shadowOpacity = 0.5f;
    self.loadingDarkRect.layer.shadowOffset = CGSizeMake(1, 2);
    
    // Parallax to loading indicator
    UIInterpolatingMotionEffect *loadingHorizontalMotion = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    loadingHorizontalMotion.minimumRelativeValue = @(-5);
    loadingHorizontalMotion.maximumRelativeValue = @(5);
    UIInterpolatingMotionEffect *loadingVerticalMotion = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    loadingVerticalMotion.minimumRelativeValue = @(-5);
    loadingVerticalMotion.maximumRelativeValue = @(5);
    [self.loadingDarkRect addMotionEffect:loadingHorizontalMotion];
    [self.loadingDarkRect addMotionEffect:loadingVerticalMotion];
    
    //register for application events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidLeaveForeground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDidBecomeUnavailible:) name:SCAudioStreamDidBecomeUnavailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackWasInterrupted:) name:AUDIO_INTERRUPTION object:nil];
    
    // Execute anything loaded in the Operation Queue
    [self.viewLoadQueue setSuspended:NO];
    
    //Hide the track Panel frame. We will animate it back in later.
    self.trackPanel.frame = CGRectOffset(self.trackPanel.frame, 0, 263.0f);
    
    //animate cloud player in
    [UIView animateWithDuration:0.5f delay:0.8f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.trackPanel.frame = CGRectOffset(self.trackPanel.frame, 0, -263.0f);
    } completion:^(BOOL finished) {}];

}



#pragma mark

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    NSArray *visiblePaths = [self.tracksTableView indexPathsForVisibleRows];
    for (int i = 0; i < self.tracksArray.count; i++) {
        
        for (NSIndexPath *indexPath in visiblePaths)
        {
            //release any images that are not currently in view
            if (indexPath.row != i) {
                TrackModel *track = [self.tracksArray objectAtIndex:i];
                track.track_image = nil;
            }
        }
    }
        
    
}

- (void)dealloc
{
    [self clearPlaylist];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

