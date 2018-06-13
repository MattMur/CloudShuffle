//
//  SoundCloudAPISingleton.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 12/31/11.
//  Copyright (c) 2011 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeModel.h"
#import "UserModel.h"
#import "TrackModel.h"
#import "SCUI.h"

#define ME @"me"
#define FAVORITES @"Favorites"
#define BAND_FAVORITES @"Band Favorites"
#define BAND_TRACKS @"Band Tracks"
#define CUSTOM_PLAYLIST @"Playlist"
#define FOLLOWINGS @"followings"
#define ADD_REMOVE_FAVORITE @"adf"
#define TRACKS_RECIEVED_NOTIFICATION @"more_tracks"
#define REQUEST_TIMEOUT 20.0

typedef enum {
    SCSPlaylistTypeBandTracks,
    SCSPlaylistTypeBandFavorites,
    SCSPlaylistTypeFavorites
} SCSPlaylistType;

extern NSString* const CLIENT_ID; 
extern NSString* const CLIENT_SECRET;
extern NSString* const REDIRECT_URL;



@protocol SoundCloudAPIManagerDelegate <NSObject>
- (void)tracksRecieved:(NSArray *)tracks didCompleteAllRequests:(BOOL)isComplete;
- (void)requestDidTimeout:(NSString *)requestIdentifier;

@end

@protocol SoundCloudLogonDelegate <NSObject>
- (void)presentLoginController:(UIViewController *)loginVC;
- (void)didCompleteLogin;
@end



@interface SoundCloudAPIManager : NSObject 

@property (weak, nonatomic) id<SoundCloudAPIManagerDelegate> delegate;
@property (weak, nonatomic) id<SoundCloudLogonDelegate> delegateLogon;
@property (strong, nonatomic) NSMutableDictionary *connectionIds; //Used to cancel connections if needed


+ (SoundCloudAPIManager *)sharedInstance;
+ (SCAccount *)account;
+ (BOOL)isUserAuthenticated;

- (void)login;
- (void)cancelAllRequests;

- (void)requestMeInfo;
- (void)requestPlaylistType:(NSString *)type delegate:(id<SoundCloudAPIManagerDelegate>)delegate;
- (void)requestUserPlaylist:(int)playlistIdx delegate:(id<SoundCloudAPIManagerDelegate>)delegate;

- (void)addFavoriteTrack:(TrackModel *)track;
- (void)removeFavoriteTrack:(TrackModel *)track;

@end
