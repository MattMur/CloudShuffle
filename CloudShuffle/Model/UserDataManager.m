//
//  UserPrefsManager.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/8/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "UserDataManager.h"
#import "SCSUtilities.h"

#define FOLLOWINGS_COUNT @"folcount"
#define FAVORITES_COUNT @"favcount"
#define BANDTRACKS_COUNT @"btrackcount"
#define BANDFAVORITES_COUNT @"bfavcount"
#define ME @"me"
#define ME_PATH @"me.dict"

@interface UserDataManager ()

- (void)saveValue:(id)value withKey:(NSString*)key;
- (id)retrieveValueWithKey:(NSString*)key;
- (BOOL)containsValueForKey:(NSString*)key;

@end



@implementation UserDataManager

@synthesize meInfo;
@synthesize followings;
@synthesize followingCount;
@synthesize favoritesCount;
@synthesize bandFavoritesCount;
@synthesize bandTracksCount;

+ (UserDataManager *)sharedInstance {
	static UserDataManager *globalInstance;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
        globalInstance = [[UserDataManager alloc] init];
    });
	return globalInstance;
}

// Getters handle retrieving value from 1 of 2 place. Either memory or from disk.
// If not availible in memory, then will attempt to retrieve the value from disk.
// Otherwise value is 0

- (int)followingsCount {
    if (favoritesCount != 0) {
        return favoritesCount;
    } else if([self containsValueForKey:FOLLOWINGS_COUNT]) {
        return [[self retrieveValueWithKey:FOLLOWINGS_COUNT] intValue];
    } else {
        return 0;
    }
}

- (int)favoritesCount {
    if (favoritesCount != 0) {
        return favoritesCount;
    } else if([self containsValueForKey:FAVORITES_COUNT]) {
        return [[self retrieveValueWithKey:FAVORITES_COUNT] intValue];
    } else {
        return 0;
    }
}

- (int)bandTracksCount {
    if (bandTracksCount != 0) {
        return bandTracksCount;
    } else if([self containsValueForKey:BANDTRACKS_COUNT]) {
        return [[self retrieveValueWithKey:BANDTRACKS_COUNT] intValue];
    } else {
        return 0;
    }
        
}

- (int)bandFavoritesCount {
    if (bandFavoritesCount != 0) {
        return bandFavoritesCount;
    } else if([self containsValueForKey:BANDFAVORITES_COUNT]) {
        return [[self retrieveValueWithKey:BANDFAVORITES_COUNT] intValue];
    } else {
        return 0;
    }
    
}

- (MeModel *)meInfo {
    if (meInfo == nil) {
        //read meInfo.dict to plist
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                             NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:ME_PATH];
        if (path) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            if (dict) {
                meInfo = [[MeModel alloc] initWithDict:dict];
            }
        }
    }
    return meInfo;
}


- (void)setMeInfo:(MeModel *)me {
    meInfo = me;
    
    //remove null values
    //NSLog(@"meinfo: %@", meInfo);
    me.dict = [SCSUtilities removeNullValuesFromDictionary:me.dict];
    
    //write to file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                         NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:ME_PATH];
    [meInfo.dict writeToFile:path atomically:YES];
    //NSLog(@"success: %@", [NSNumber numberWithBool:success]);
}

- (void)setFollowingCount:(int)follCount {
    followingCount = follCount;
    [self saveValue:[NSNumber numberWithInt:follCount] withKey:FOLLOWINGS_COUNT];
}

- (void)setFavoritesCount:(int)favCount {
    favoritesCount = favCount;
    [self saveValue:[NSNumber numberWithInt:favCount] withKey:FAVORITES_COUNT];
}

- (void)setBandTracksCount:(int)bTracksCount {
    bandTracksCount = bTracksCount;
    [self saveValue:[NSNumber numberWithInt:bTracksCount] withKey:BANDTRACKS_COUNT];
}

- (void)setBandFavoritesCount:(int)bFavoritesCount {
    bandFavoritesCount = bFavoritesCount;
    [self saveValue:[NSNumber numberWithInt:bFavoritesCount] withKey:BANDFAVORITES_COUNT];
}


- (void)saveValue:(id)value withKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:value forKey:key];
}

- (id)retrieveValueWithKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    id value = [prefs objectForKey:key];
    return value;
}

- (BOOL)containsValueForKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    id value = [prefs objectForKey:key];
    if (value == nil) {
        return NO;
    } else {
        return YES;
    }
    
}

- (void)clearAllData
{
    //NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    self.bandTracksCount = 0;
    self.bandFavoritesCount = 0;
    self.favoritesCount = 0;
    self.followings = nil;
    self.playlists = nil;
}

@end
