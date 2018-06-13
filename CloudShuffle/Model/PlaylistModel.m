//
//  PlaylistModel.m
//  CloudShuffle
//
//  Created by Matt Murray on 5/20/14.
//  Copyright (c) 2014 Special Ops Development. All rights reserved.
//

#import "PlaylistModel.h"
#import "TrackModel.h"

@implementation PlaylistModel {
    NSMutableArray *_trackArray;
}

- (NSNumber *)playlist_id
{
    return self.dict[@"id"];
}

- (NSString *)title
{
    return self.dict[@"title"];
}

- (NSNumber *)trackCount
{
    return self.dict[@"track_count"];
}

- (NSArray *)tracks
{
    if (!_trackArray) {
        _trackArray = [NSMutableArray array];
        [self.dict[@"tracks"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            TrackModel *track = [[TrackModel alloc] initWithDict:obj];
            [_trackArray addObject:track];
        }];
    }
    return _trackArray;
}


@end
