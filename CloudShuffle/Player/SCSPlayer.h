//
//  SCSPlayer.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/21/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SCAudioStream.h"
#import "TrackModel.h"

#define AUDIO_INTERRUPTION @"adIntrptn"

@protocol SCSPlayerDelegate <NSObject>
//Called when the selected track changes
// audio streams used to attach observers
- (void)trackChangedToIndex:(int)index;

@optional
- (void)setObserversOnStream:(SCAudioStream *)stream;
- (void)removeObserversOnStream:(SCAudioStream *)stream;
@end


@interface SCSPlayer : UIResponder <AVAudioSessionDelegate, AVAudioPlayerDelegate> {
    id<SCSPlayerDelegate> __weak delegate_;
}

@property (weak, nonatomic) TrackModel *selectedTrack;
@property (assign) NSInteger selectedIndex;
@property (weak) NSMutableArray *playlist;  //datasource
@property (weak) id<SCSPlayerDelegate> delegate;
@property (assign) BOOL isBuffering;

//SoundCloud API
@property (strong) SCAudioStream *audioStream;

+ (SCSPlayer *)sharedInstance;

- (void)setNewPlaylist:(NSMutableArray *)playlist;
- (void)setNewTrack:(NSInteger)index;
- (void)startBufferNextStream;
- (void)play;
- (void)pause;
- (void)previousSong;
- (void)nextSong;
- (void)seekToMillisecond:(NSUInteger)milli startPlaying:(BOOL)play;

@end
