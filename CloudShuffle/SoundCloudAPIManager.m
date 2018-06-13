//
//  SoundCloudAPISingleton.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 12/31/11.
//  Copyright (c) 2011 SpecialOps Development. All rights reserved.
//

#import "SoundCloudAPIManager.h"
#import "AppDelegate.h" 
#import "UserDataManager.h"
#import "PlaylistModel.h"
#import "SCSUtilities.h"
#import "TestFlight.h"
#include <stdlib.h>


#define TRACKS_PER_REQUEST 10
#define PLAYLIST_MAX_SIZE 75


#define INITIAL_REQUEST @"req1"

@interface SoundCloudAPIManager ()
@property (nonatomic, strong) NSTimer *requestTimer;
- (NSURL *)urlWithSCRequestString:(NSString *)reqStr;
- (void)requestUserFavorites;
- (void)requestBandTracks;
- (void)requestBandFavorites;
@end


@implementation SoundCloudAPIManager

@synthesize delegate = _delegate;
@synthesize delegateLogon = _delegateLogon;
@synthesize connectionIds;
@synthesize requestTimer = _requestTimer;


typedef enum {
    SoundCloudReturnType_Me,
    SoundCloudReturnType_Followings,
    SoundCloudReturnType_BandTracks,
    SoundCloudReturnType_BandFavorites,
    SoundCloudReturnType_UserFavorites
} SoundCloudReturnType;

NSString* const CLIENT_ID = @"fc44d4dd44289cdef1080bd315147435"; 
NSString* const CLIENT_SECRET = @"cdbd28e7de95e65448d6f1569da11190";
NSString* const REDIRECT_URL = @"scshuffle://home/oauth";



+ (SoundCloudAPIManager *)sharedInstance {
	static SoundCloudAPIManager *globalInstance;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
        globalInstance = [[SoundCloudAPIManager alloc] init];
        globalInstance.connectionIds = [NSMutableDictionary dictionary];
        
        // Initialize the SoundCloud API
        [SCSoundCloud setClientID:CLIENT_ID
                           secret:CLIENT_SECRET
                      redirectURL:[NSURL URLWithString:REDIRECT_URL]];
    });
	return globalInstance;
}

+ (SCAccount *)account
{
    SCAccount *account = [SCSoundCloud account];
    if (account == nil) {
        [[SoundCloudAPIManager sharedInstance] login];
    }
    return account;
}

// Concatenate string into json request for SoundCloud
- (NSURL *)urlWithSCRequestString:(NSString *)reqStr
{
    NSString *requestStr = [NSString stringWithFormat:@"https://api.soundcloud.com%@", reqStr];
    NSLog(@"request: %@",requestStr);
    return [NSURL URLWithString:requestStr];
}


- (void)login
{
    
     SCLoginViewControllerCompletionHandler handler = ^(NSError *error) {
         [[UIApplication sharedApplication] setStatusBarHidden:NO];
         if (SC_CANCELED(error)) {
             NSLog(@"Canceled!");
             
         } else if (error) {
             
             NSLog(@"Error: %@", [error localizedDescription]);
             // [TestFlight passCheckpoint:@"Authentication failed"];
             NSString *message = [NSString stringWithFormat:@"%@. Please try again. ", error.localizedDescription];
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
             [alert show];
             
         } else {
             if (self.delegateLogon) {
                 [self.delegateLogon didCompleteLogin];
             }
         }
     };
     
     [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        SCLoginViewController *loginViewController;
        
        loginViewController = [SCLoginViewController
                               loginViewControllerWithPreparedURL:preparedURL
                               completionHandler:handler];
        if (self.delegateLogon) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            [self.delegateLogon presentLoginController:loginViewController];
        }
      
    }];
}

+ (BOOL)isUserAuthenticated
{
    return ([SCSoundCloud account] != nil);
}


//Returns and array of NSStrings in Range format. Use NSRangeFromString() to convert to NSRange.
// NSRanges used to make requests on randomized ranges of tracks
- (NSArray *)getRandomRangesOfTracksWithTotal:(int)totalTracks tracksPerRequest:(int)tracksPer maxRequests:(int)maxRequests   {
    NSMutableArray *rangesArray = nil;
    
    //If we have less than PLAYLIST_MAX_SIZE, then we won't randomize track selection
    if (totalTracks < tracksPer * maxRequests) {
        rangesArray = [NSMutableArray arrayWithCapacity: 1];
        NSRange requestRange = NSMakeRange( 0 , totalTracks);
        [rangesArray addObject: NSStringFromRange(requestRange)];
        
    } else {
        //Calculate the total number of request possible
        int totalRequests = totalTracks / tracksPer;
        rangesArray = [NSMutableArray arrayWithCapacity: maxRequests];
        NSMutableArray *possibleRequestsArray = [NSMutableArray arrayWithCapacity:totalRequests];
        
        //fill helper array, 1 number for each possible request
        for (int i = 0; i < totalRequests; i++)
        {
            [possibleRequestsArray addObject:[NSNumber numberWithInt:i]];
        }
        
        
        //Only allow up to 4 requests
        int requestCount = MIN(totalRequests, maxRequests);
        
        //Here we are trying to get a randomly selected offset for each request
        // the possibleRequests array contains the offsets for each possible request
        // we use random to randomly select an offset from helper array
        for (int i = 0; i < requestCount; i++) {

            int random = (arc4random() % possibleRequestsArray.count);
            
            //create a range for each randomly selected offset position;
            NSNumber *offsetPos = [possibleRequestsArray objectAtIndex:random];
            NSRange requestRange = NSMakeRange( ([offsetPos intValue] * tracksPer) , tracksPer);
            [rangesArray addObject: NSStringFromRange(requestRange)];
            
            //remove value from array so it can never be selected again
            [possibleRequestsArray removeObjectAtIndex:random]; 
        }
    }
    
    return rangesArray;
}

- (void)requestTracksOnResourceUri:(NSString *)resourceUri withRange:(NSRange)range
{
    //create offset parameters
    NSMutableDictionary *params = nil;
    if (range.location != NSNotFound) {
        NSString *trackLimitStr = [NSString stringWithFormat:@"%lu", (unsigned long)range.length];
        NSString *offsetStr = [NSString stringWithFormat:@"%lu", (unsigned long)range.location];
        params = [NSMutableDictionary dictionaryWithObjectsAndKeys:trackLimitStr, @"limit", offsetStr, @"offset", nil];
    }
    //NSLog(@"parameters: %@", params);
    
    
    //prepare index so that connection can be cancelled if needed
    NSNumber *index = @(self.connectionIds.count);
    
    //make the request with response handler
    id connectionId = [SCRequest performMethod:SCRequestMethodGET
                      onResource:[self urlWithSCRequestString:resourceUri]
                 usingParameters:params
                     withAccount:[SoundCloudAPIManager account]
          sendingProgressHandler:nil
                 responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                     
                     if (!error) {
                         //Do this for anything that is downloading tracks for PlaylistViewController
                         //If this is the first data packet to come back then notify delegate
                         NSArray *trackArray = [SCSUtilities tracksFromData:responseData];
                         if (trackArray) {
                             [self.connectionIds removeObjectForKey:index]; //everything successful. safe to remove.
                             NSLog(@"connection completed: %@", index);
                             if (trackArray.count > 0) {
                                 
                             } else {
                                 NSLog(@">>>> count is 0");
                             }
                             BOOL didComplete = (self.connectionIds.count == 0 ? YES : NO);
                             if (self.delegate) {
                                 [self.delegate tracksRecieved:trackArray didCompleteAllRequests:didComplete];
                             }

                         }
                     } else {
                         NSLog(@"SoundCloudAPI Error: %@", error.localizedDescription);
                     }
                     
                 }];
    
    [self.connectionIds setObject:connectionId forKey:index];
}


- (void)requestMeInfo
{
    NSLog(@"Request User Info");
    
    SCRequestResponseHandler meHandler;
     meHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
         
         if (!error) {
             UserDataManager *userManager = [UserDataManager sharedInstance];
             MeModel *me = [[MeModel alloc] initWithJSONData:data];
             [userManager setMeInfo: me];
             userManager.favoritesCount = [me.public_favorites_count intValue];
         } else {
             NSLog(@"SoundCloudAPI Error: %@", error.localizedDescription);
         }
         
     };
    
    
    SCRequestResponseHandler followersHandler;
    followersHandler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (!error) {
            UserDataManager *userManager = [UserDataManager sharedInstance];
            NSError *jsonerror = nil;
            NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonerror];
            
            if (jsonerror != nil) {
                NSLog(@"An error occurred: %@", jsonerror.localizedDescription);
            } else {
                //Grab dictionaries and wrap them in UserModel objects
                NSMutableArray *followingsArray = nil;
                if (dataArray) {
                    followingsArray = [NSMutableArray arrayWithCapacity:[dataArray count]];
                    for (NSDictionary *userDict in dataArray) {
                        UserModel *user = [[UserModel alloc] initWithDict:userDict];
                        [followingsArray addObject:user];
                    }
                } else {
                    followingsArray = [NSMutableArray array];
                }
                
                //save to UserManager
                userManager.followings = followingsArray;
                //userManager.followingCount = followingsArray.count; //This will cache the value. Needed later...
                
                //count all band tracks and band favorites
                int track_count = 0;
                int favorites_count = 0;
                for (UserModel *user in followingsArray) {
                    track_count += [user.track_count intValue];
                    favorites_count += [user.public_favorites_count intValue];
                }
                userManager.bandTracksCount = track_count;
                userManager.bandFavoritesCount = favorites_count;
            }

        } else {
            NSLog(@"SoundCloudAPI Error: %@", error.localizedDescription);
        }
        
    };

    // request user info
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[self urlWithSCRequestString:@"/me.json"]
             usingParameters:nil
                 withAccount:[SoundCloudAPIManager account]
      sendingProgressHandler:nil
             responseHandler:meHandler];
    
    // request info on accounts that the user is following
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[self urlWithSCRequestString:@"/me/followings.json"]
             usingParameters: [NSDictionary dictionaryWithObject:@"200" forKey:@"limit"] // default is 50, 200 is max we can do
                 withAccount:[SoundCloudAPIManager account]
      sendingProgressHandler:nil
             responseHandler:followersHandler];
    
    // request info on playlists that user has
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[self urlWithSCRequestString:@"/me/playlists"]
             usingParameters:nil
                 withAccount:[SoundCloudAPIManager account]
      sendingProgressHandler:nil
             responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                 
                 UserDataManager *userManager = [UserDataManager sharedInstance];
                 NSError *jsonerror = nil;
                 NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:responseData options:nil error:&jsonerror];
                 NSMutableArray *playlistsArray = [NSMutableArray array];
                 
                 if (dataArray) {
                     [dataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                         PlaylistModel *playlist = [[PlaylistModel alloc] initWithDict:obj];
                         [playlistsArray addObject:playlist];
                         //NSLog(@"playlist model: %@", playlist);
                     }];
                     // Add playlist data to userdata singleton
                     userManager.playlists = [NSArray arrayWithArray:playlistsArray];
                 } else {
                     if (jsonerror) {
                         NSLog(@"%@", jsonerror);
                     }
                 }
    }];
    
}

- (void)requestPlaylistType:(NSString *)type delegate:(id<SoundCloudAPIManagerDelegate>)delegate
{
    self.delegate = delegate;
    if ([type isEqualToString:FAVORITES]) {
        [self requestUserFavorites];
    } else if ([type isEqualToString:BAND_TRACKS]) {
        [self requestBandTracks];
    } else if ([type isEqualToString:BAND_FAVORITES]) {
        [self requestBandFavorites];
    } else {
        // search playlists with same name
        __block BOOL success = NO;
        NSArray *playlists = [UserDataManager sharedInstance].playlists;
        [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PlaylistModel *playlist = obj;
            if ([playlist.title isEqualToString:type]) {
                [self requestUserPlaylist:(int)idx delegate:delegate];
                success = YES;
            }
        }];
        if (!success) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not find selected playlist. Try reloading and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)requestUserPlaylist:(int)playlistIdx delegate:(id<SoundCloudAPIManagerDelegate>)delegate
{
    //create timeout timer
    self.requestTimer = [NSTimer scheduledTimerWithTimeInterval:REQUEST_TIMEOUT target:self selector:@selector(requestDidTimeout:) userInfo:CUSTOM_PLAYLIST repeats:NO];
    NSLog(@"Request User Playlist");
    
    // We already should have the playlist, since it was downloaded in beginning. No way to not download as far as I know.
    NSArray *playlists = [UserDataManager sharedInstance].playlists;
    if (playlists.count > playlistIdx) {
        if ([delegate respondsToSelector:@selector(tracksRecieved:didCompleteAllRequests:)]) {
            PlaylistModel *playlist = playlists[playlistIdx];
            NSArray *tracks = [SCSUtilities shuffleArray:playlist.tracks]; // shuffle tracks
            [self.delegate tracksRecieved:tracks didCompleteAllRequests:YES];
        }
    }
    
}

- (void)requestUserFavorites
{
    //create timeout timer
    self.requestTimer = [NSTimer scheduledTimerWithTimeInterval:REQUEST_TIMEOUT target:self selector:@selector(requestDidTimeout:) userInfo:FAVORITES repeats:NO];
    NSLog(@"Request User Favorites");
    
    UserDataManager *userManager = [UserDataManager sharedInstance];
    NSArray *requestRanges = [self getRandomRangesOfTracksWithTotal:userManager.favoritesCount tracksPerRequest:25 maxRequests:4];
    
    for (NSString *rngStr in requestRanges) {
        NSRange range = NSRangeFromString(rngStr);
        [self requestTracksOnResourceUri:@"/me/favorites.json" withRange:range];
    }
    
}

- (void)requestBandTracks
{
    //create timeout timer
    self.requestTimer = [NSTimer scheduledTimerWithTimeInterval:REQUEST_TIMEOUT target:self selector:@selector(requestDidTimeout:) userInfo:BAND_TRACKS repeats:NO];
    NSLog(@"Request Band Tracks");
    
    UserDataManager *userManager = [UserDataManager sharedInstance];
    NSArray *requestRanges = [self getRandomRangesOfTracksWithTotal:userManager.bandTracksCount tracksPerRequest:25 maxRequests:4];
    
    for (NSString *rngStr in requestRanges) {
        NSRange range = NSRangeFromString(rngStr);
        [self requestTracksOnResourceUri:@"/me/followings/tracks" withRange:range]; //NOT json (not supported)
    }
    
}

- (void)requestBandFavorites
{
    //create timeout timer
    NSLog(@"Request Band Favorites");
    
    UserDataManager *userManager = [UserDataManager sharedInstance];
    
    //while track count is less than 100
    int trackCount = 0;
    int maxPlaylistSize = MIN(PLAYLIST_MAX_SIZE, userManager.bandFavoritesCount);
    while (trackCount < maxPlaylistSize) {
        
        //randomize which user
        int totalFollowers = (int)userManager.followings.count;
        int randomUser = (arc4random() % totalFollowers);
        UserModel *followedUser = [userManager.followings objectAtIndex:randomUser];
        int numTracks = [followedUser.public_favorites_count intValue];
        if (numTracks == 0) continue; // continue if user has no favorites
        
        //randomize range of tracks from that user
        int randomTracks = (arc4random() % MIN(numTracks, 10)) + 1;
        // If numtracks is less than 10 then we always just do 1 request. Otherwize up to 4 requests.
        int randomRequests = (arc4random() % MIN(numTracks/randomTracks, 4)) + 1;
        
        //Make sure we dont go over the PLAYLIST_MAX_SIZE
        if (trackCount + (randomTracks * randomRequests) > PLAYLIST_MAX_SIZE) {
            randomRequests = 1;
            if ( (trackCount + randomTracks) > PLAYLIST_MAX_SIZE) {
                randomTracks = PLAYLIST_MAX_SIZE - trackCount;
            }
        }
        
        self.requestTimer = [NSTimer scheduledTimerWithTimeInterval:REQUEST_TIMEOUT target:self selector:@selector(requestDidTimeout:) userInfo:BAND_FAVORITES repeats:NO];
        
        NSArray *requestRanges = [self getRandomRangesOfTracksWithTotal:numTracks tracksPerRequest:randomTracks maxRequests:randomRequests];
        
        //Make a separate request for each range
        NSString *resource = [NSString stringWithFormat:@"/users/%@/favorites.json", followedUser.user_id];
        for (NSString *rngStr in requestRanges) {
            NSRange range = NSRangeFromString(rngStr);
            [self requestTracksOnResourceUri:resource withRange:range];
            
        }
        
        // sum total tracks added
        trackCount += randomTracks * randomRequests;
    }
    
}

- (void)addFavoriteTrack:(TrackModel *)track {
    //NSLog(@"\nfavorite resource:%@", favStr);
    NSString *favStr = [NSString stringWithFormat:@"/me/favorites/%@", track.track_id];
    [SCRequest performMethod:SCRequestMethodPUT
                  onResource:[self urlWithSCRequestString:favStr]
             usingParameters:nil
                 withAccount:[SoundCloudAPIManager account]
      sendingProgressHandler:nil
             responseHandler:nil];
}

- (void)removeFavoriteTrack:(TrackModel *)track {
    
    NSString *removeUrl = [NSString stringWithFormat:@"/me/favorites/%@", track.track_id];
    [SCRequest performMethod:SCRequestMethodDELETE
                  onResource:[self urlWithSCRequestString:removeUrl]
             usingParameters:nil
                 withAccount:[SoundCloudAPIManager account]
      sendingProgressHandler:nil
             responseHandler:nil];
}

- (void)cancelAllRequests
{
    NSLog(@"Requests cancelled");

    NSArray *connections = [self.connectionIds allValues];
    for (id connectionId in connections) {
        [SCRequest cancelRequest:connectionId];
    }
    [self.connectionIds removeAllObjects];
}

- (void)requestDidTimeout:(id)sender
{
    //If requests are still being made, cancel them and notify delegate
    NSTimer *timer = (NSTimer *)sender;
    int count = (int)[[self.connectionIds allValues] count];
    if (count > 0) {
        NSLog(@"Did time out %@", timer.userInfo);
        [self cancelAllRequests];
        if ([self.delegate respondsToSelector:@selector(requestDidTimeout:)]) {
            [self.delegate requestDidTimeout:timer.userInfo];
        }
        
        if (self.requestTimer) {
            [self.requestTimer invalidate];
            self.requestTimer = nil;
        }
    }  else {
        //NSLog(@"Did not time out %@", timer.userInfo);
    }
}

- (void)dealloc
{
    [self.connectionIds removeAllObjects];
}


@end
