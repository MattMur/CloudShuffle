//
//  Track.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"
#import "UserModel.h"

@interface TrackModel : BaseModel

@property (weak, nonatomic, readonly) NSNumber *track_id;
@property (weak, nonatomic, readonly) NSNumber *user_id;
@property (weak, nonatomic, readonly) UserModel *artist;
@property (weak, nonatomic, readonly) NSString *title;
@property (weak, nonatomic, readonly) NSString *artwork_url;
@property (weak, nonatomic, readonly) NSString *trackDescription;
@property (weak, nonatomic, readonly) NSNumber *duration;
@property (weak, nonatomic, readonly) NSString *genre;
@property (weak, nonatomic, readonly) NSString *waveform_image_url;
@property (weak, nonatomic, readonly) NSString *stream_url;
@property (nonatomic, readonly) NSString *permalink_url;
@property (nonatomic) BOOL is_user_favorite;
@property (nonatomic) BOOL streamable;
@property (nonatomic, strong) UIImage *track_image; //downloaded image from url


@end
