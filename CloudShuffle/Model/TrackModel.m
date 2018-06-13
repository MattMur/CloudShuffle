//
//  Track.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "TrackModel.h"

@implementation TrackModel

@synthesize track_id, user_id, artist, title, artwork_url, description, duration, genre, waveform_image_url, stream_url,is_user_favorite;
@synthesize track_image;

- (NSNumber *) track_id
{
    return [self.dict objectForKey:@"id"];
}

- (NSNumber *) user_id
{
    return [self.dict objectForKey:@"user-id"];
}

- (NSNumber *) duration
{
    return [self.dict objectForKey:@"duration"];
}

- (UserModel *) artist
{
    UserModel *user = [[UserModel alloc] init];
    user.dict = [self.dict objectForKey:@"user"];
    return user;
}

- (NSString *) title
{
    return [self.dict objectForKey:@"title"];
}

- (NSString *) artwork_url
{
    return [self.dict objectForKey:@"artwork_url"];
}

- (NSString *) trackDescription
{
    return [self.dict objectForKey:@"description"];
}

- (NSString *) genre
{
    return [self.dict objectForKey:@"genre"];
}

- (NSString *) waveform_image_url
{
    return [self.dict objectForKey:@"waveform_url"];
}

- (NSString *) stream_url
{
    return [self.dict objectForKey:@"stream_url"];
}

- (NSString *) track_url
{
    return [self.dict objectForKey:@"uri"];
}

- (NSString *)permalink_url
{
    return [self.dict objectForKey:@"permalink_url"];
}

- (BOOL) is_user_favorite
{
    return [[self.dict objectForKey:@"user_favorite"] boolValue];
}

- (BOOL) streamable {
    return [self.dict[@"streamable"] boolValue];
}

- (void) setIs_user_favorite:(BOOL)is_favorite
{
    NSMutableDictionary *changeDict = [NSMutableDictionary dictionaryWithDictionary:self.dict];
    [changeDict setObject:[NSNumber numberWithBool:is_favorite] forKey:@"user_favorite"];
    self.dict = changeDict;
}

- (NSString *)description
{
    NSString *str = [NSString stringWithFormat:@"%@ %@", [super description], [self dict]];
    return str;
}




@end
