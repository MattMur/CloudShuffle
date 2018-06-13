//
//  UserPrefsManager.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/8/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeModel.h"
#import "UserModel.h"

#define LIMIT_SONGS @"ls"

// Used as a Singelton to manage data storage and retrieval
// Works simutaniously with memory and harddrive
@interface UserDataManager : NSObject

// Cached values
@property (strong, nonatomic) MeModel *meInfo;
@property (assign, nonatomic) int followingCount;
@property (assign, nonatomic) int favoritesCount;
@property (assign, nonatomic) int bandTracksCount;
@property (assign, nonatomic) int bandFavoritesCount;

@property (strong, nonatomic) NSArray *followings; //Array of users being followed
@property (nonatomic) NSArray *playlists; // array of PlaylistModel


+ (UserDataManager *)sharedInstance;

/*- (void)setPlaylistTrackCountWithId:(NSUInteger)playlistId;
- (NSUInteger)getPlaylistTrackCountWithId:(NSUInteger)playlistId;

- (void)setPlaylistNameWithId:(NSUInteger)playlistId;
- (NSString *)getPlaylistNameWithId:(NSUInteger)playlistId;
 */

- (void)clearAllData;

@end
