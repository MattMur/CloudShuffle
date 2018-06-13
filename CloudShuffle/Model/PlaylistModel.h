//
//  PlaylistModel.h
//  CloudShuffle
//
//  Created by Matt Murray on 5/20/14.
//  Copyright (c) 2014 Special Ops Development. All rights reserved.
//

#import "BaseModel.h"

@interface PlaylistModel : BaseModel

@property (nonatomic) NSNumber *playlist_id;
@property (nonatomic) NSString *title;
@property (nonatomic) NSNumber* trackCount;
@property (nonatomic) NSArray *tracks;

@end
