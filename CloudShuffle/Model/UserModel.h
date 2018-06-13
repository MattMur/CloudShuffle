//
//  User.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface UserModel : BaseModel

@property (weak, nonatomic, readonly) NSNumber *user_id;
@property (weak, nonatomic, readonly) NSString *permalink;
@property (weak, nonatomic, readonly) NSString *username;
@property (weak, nonatomic, readonly) NSString *url;
@property (weak, nonatomic, readonly) NSString *permalink_url;
@property (weak, nonatomic, readonly) NSString *avatar_url;
@property (weak, nonatomic, readonly) NSString *country;
@property (weak, nonatomic, readonly) NSString *full_name;
@property (weak, nonatomic, readonly) NSString *city;
@property (weak, nonatomic, readonly) NSString *user_description;
@property (weak, nonatomic, readonly) NSString *discogs_name;
@property (weak, nonatomic, readonly) NSString *myspace_name;
@property (weak, nonatomic, readonly) NSString *website;
@property (weak, nonatomic, readonly) NSString *website_title;
@property (nonatomic, readonly) BOOL online;
@property (weak, nonatomic, readonly) NSNumber *track_count;
@property (weak, nonatomic, readonly) NSNumber *playlist_count;
@property (weak, nonatomic, readonly) NSNumber *followers_count;
@property (weak, nonatomic, readonly) NSNumber *followings_count;
@property (weak, nonatomic, readonly) NSNumber *public_favorites_count;


@end
