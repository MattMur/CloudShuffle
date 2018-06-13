//
//  Me.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

@interface MeModel : UserModel

@property (weak, nonatomic, readonly) NSNumber *private_tracks_count;
@property (weak, nonatomic, readonly) NSNumber *private_playlist_count;
@property (nonatomic, readonly) BOOL primary_email_confirmed;


@end
