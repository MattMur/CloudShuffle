//
//  Me.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "MeModel.h"

@implementation MeModel

@synthesize private_tracks_count, private_playlist_count, primary_email_confirmed;


- (NSNumber *)private_tracks_count
{
    return [self.dict objectForKey:@"private_tracks_count"];
}

- (NSNumber *)private_playlist_count
{
    return [self.dict objectForKey:@"private_playlist_count"];
}

- (BOOL)primary_email_confirmed
{
    return [[self.dict objectForKey:@"primary_email_confirmed"] boolValue];
}




@end
