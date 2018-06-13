//
//  User.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel

@synthesize user_id, permalink, username, url, permalink_url, avatar_url, country, 
full_name, city, user_description, discogs_name, myspace_name, website, website_title, 
online, track_count, playlist_count, followers_count, followings_count, public_favorites_count;

- (NSString *)user_id
{
    return [self.dict objectForKey:@"id"];
}

- (NSString *)permalink
{
    return [self.dict objectForKey:@"permalink"];
}

- (NSString *)username
{
    return [self.dict objectForKey:@"username"];
}

- (NSString *)url
{
    return [self.dict objectForKey:@"url"];
}

- (NSString *)avatar_url
{
    return [self.dict objectForKey:@"avatar_url"];
}

- (NSString *)country
{
    return [self.dict objectForKey:@"country"];
}

- (NSString *)full_name
{
    return [self.dict objectForKey:@"full_name"];
}

- (NSString *)city
{
    return [self.dict objectForKey:@"city"];
}

- (NSString *)discogs_name
{
    return [self.dict objectForKey:@"discogs-name"];
}

- (NSString *)user_description
{
    return [self.dict objectForKey:@"description"];
}

- (NSString *)myspace_name
{
    return [self.dict objectForKey:@"myspace_name"];
}

- (NSString *)website
{
    return [self.dict objectForKey:@"website"];
}

- (NSString *)website_title
{
    return [self.dict objectForKey:@"website-title"];
}

- (BOOL)online
{
    return [[self.dict objectForKey:@"online"] boolValue];
}

- (NSNumber *)track_count
{
    return [self.dict objectForKey:@"track_count"];
}

- (NSNumber *)playlist_count
{
    return [self.dict objectForKey:@"playlist_count"];
}

- (NSNumber *)followers_count
{
    return [self.dict objectForKey:@"followers_count"];
}

- (NSNumber *)followings_count
{
    return [self.dict objectForKey:@"followings_count"];
}

- (NSNumber *)public_favorites_count
{
    return [self.dict objectForKey:@"public_favorites_count"];
}



@end
