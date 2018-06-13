//
//  SCSPlayer.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/21/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "SCSPlayer.h"
#import "SoundCloudAPIManager.h"
#import "PlaylistViewController.h"
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>



@interface SCSPlayer () {
   UIBackgroundTaskIdentifier bgTaskId; 
}
@property (assign, nonatomic) BOOL shouldResume; //used after interruption
@property (assign, nonatomic) BOOL isActive;
@property (strong) SCAudioStream *bufferStream;
@end

@implementation SCSPlayer

@synthesize bufferStream;
@synthesize audioStream;
@synthesize playlist = _playlist;
@synthesize selectedIndex;
@synthesize selectedTrack;
@synthesize isActive;
@synthesize delegate = delegate_;
@synthesize shouldResume;
@synthesize isBuffering;


+ (SCSPlayer *)sharedInstance
{
    static SCSPlayer *globalInstance;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
        globalInstance = [[SCSPlayer alloc] init];
        globalInstance.audioStream = nil;
        globalInstance.bufferStream = nil;
        globalInstance.playlist = nil;
        globalInstance.isActive = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:globalInstance selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        //register for remote control events
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
    });
	return globalInstance;
}


- (void)setNewPlaylist:(NSMutableArray *)playlist
{
    self.playlist = playlist;
    self.selectedTrack = nil;
    self.selectedIndex = 0;
    [self setNewTrack:0];
}

- (void)appDidBecomeActive:(NSNotification *) notification {
    if (self.delegate) {
        [self.delegate trackChangedToIndex:(int)self.selectedIndex];
    }
}

- (void)startBufferNextStream {
    if (!bufferStream) {
        //make sure there is a track to buffer
        if (self.selectedIndex < ([self.playlist count] - 2)) {
            //init buffer stream
            //NSLog(@"next stream buffering");
            TrackModel *bufferTrack = [self.playlist objectAtIndex:(self.selectedIndex + 1)];
            NSURL *url = [NSURL URLWithString:bufferTrack.stream_url];
            //SCSoundCloudAPIAuthentication *auth = [[SoundCloudAPIManager scAPI] authentication];
            self.bufferStream = [[SCAudioStream alloc] initWithURL:url
                                                     authentication:[SCSoundCloud account]];
        }
    }
}



- (void)startAudioSession
{
    NSError *audioError = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&audioError];
    BOOL success = [session setActive:YES error:&audioError];
    if (!success) {
        NSLog(@"%@", [audioError localizedDescription]);
    } else {
        // Register for notifications when Audio Session is interrupted
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionInterruptionNotification object:nil queue:nil usingBlock:^(NSNotification *note) {

            // Check type of interruption
            uint interruptionType = [[note.userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntValue];
            switch (interruptionType) {
                    
                case AVAudioSessionInterruptionTypeBegan:
                    // Pause for now but resume playing later
                    self.shouldResume = (self.audioStream.playState == SCAudioStreamState_Playing ? YES : NO);
                    [self pause];
                    
                    //cancel background task
                    [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
                    bgTaskId = UIBackgroundTaskInvalid;
                    
                    //unregister for remote control events and notifications
                    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionMediaServicesWereResetNotification object:nil];
                    [self resignFirstResponder];

                    break;
                    
                case AVAudioSessionInterruptionTypeEnded:
                    if (self.shouldResume) {
                        //resume audio playback if it was playing before interruption
                        [self startAudioSession];
                        
                        //register for remote control events
                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        
                        //start new background task
                        bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                            [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
                            bgTaskId = UIBackgroundTaskInvalid;
                        }];
                        
                        if (self.shouldResume) {
                            [self play];
                        }
                    }
                    
                default:
                    break;
            }
        }];
        
        // Notification for when a new device is plugged in or taken away
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//            NSString *str = [NSString stringWithFormat:@"Input availibility changed: %c", isInputAvailable];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Input Changed" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//            [alert show];
            
            uint routeType = [[note.userInfo objectForKey:AVAudioSessionRouteChangeReasonKey] unsignedIntValue];
            switch (routeType) {
                case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
                    if (shouldResume) {
                        [self play];
                    }
                    break;
                    
                case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                    self.shouldResume = (self.audioStream.playState == SCAudioStreamState_Playing ? YES : NO);
                    [self pause];
                    break;
                default:
                    break;
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self nextSong];
        }];
        
    }
    self.isActive = YES;
}


#pragma mark - Player Control

- (void)play {
    if (!self.isActive) {
        [self startAudioSession];
    }
    if (self.playlist.count > 0 && !self.selectedTrack) {
        [self setNewTrack:0];
    }
    if (self.selectedTrack.streamable) {
        [self.audioStream play];
    } else {
        //NSLog(@"Play me Download!");
        [self nextSong];
    }
    
}

- (void)pause {
    if (self.selectedTrack) {
        [self.audioStream pause];
    }
}

- (void)seekToMillisecond:(NSUInteger)milli startPlaying:(BOOL)play
{
    self.isBuffering = YES;
    [self.audioStream seekToMillisecond:milli startPlaying:play];
}

- (void)previousSong
{
    if (self.audioStream.playPosition > 3000 || self.selectedIndex <= 0) {
        self.isBuffering = YES;
        [self.audioStream seekToMillisecond:0 startPlaying:YES];
    } else {
        //go back one track
        [self.audioStream pause];
        self.selectedIndex--;
        [self setNewTrack:self.selectedIndex];
        [self play];
    }
}


- (void)nextSong
{
    
    //stop if at end of playlist
    if (self.selectedIndex >= ([self.playlist count] - 1)) {
        return;
    }
    
    self.selectedIndex++;
    
    //setup background task
    UIBackgroundTaskIdentifier newTaskId;
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
        [[UIApplication sharedApplication] endBackgroundTask: bgTaskId];
        bgTaskId = UIBackgroundTaskInvalid;
    }];
    
    //play new track
    [self setNewTrack:self.selectedIndex];
    [self play];
    
    if (bgTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask: bgTaskId];
    }
    
    bgTaskId = newTaskId;
    
}


#pragma mark - Play New Track

- (void)setNewTrack:(NSInteger)index
{
    // Is track stream or download?
    self.selectedIndex = index;
    self.selectedTrack = [self.playlist objectAtIndex:index];
    if (self.selectedTrack.streamable) {
        [self streamTrack];
    } else {
        //[self downloadTrack];
    }
}

- (void)streamTrack {
    //remove observer on previous audio stream
    [self.audioStream removeObserver:self forKeyPath:@"playState"];
    if ([self.delegate respondsToSelector:@selector(removeObserversOnStream:)] && self.audioStream) {
        [self.delegate removeObserversOnStream:self.audioStream];
    }
    
    //Stop current stream
    [self.audioStream stop];
    
    self.isBuffering = YES;
   
    //Load from buffer if availible
    if (self.bufferStream) {
        NSLog(@"Playing from buffer");
        self.audioStream = self.bufferStream;
        self.bufferStream = nil;
    } else {
        
        //init audio stream
        NSURL *url = [NSURL URLWithString:self.selectedTrack.stream_url];
        
        //validate object and stream
        if (!url) {
            NSLog(@"Track not streamable");
            self.audioStream = nil;
            [self nextSong];
            return;
        } else {
            //NSLog(@"streamurl: %@", url);
            self.audioStream = [[SCAudioStream alloc] initWithURL:url
                                                   authentication:[SCSoundCloud account]];
        }
        
    }
    
    //observe playstate and bufferstate of audioStream
    [self.audioStream addObserver:self forKeyPath:@"playState" options:NSKeyValueObservingOptionNew context:nil];
    if ([self.delegate respondsToSelector:@selector(setObserversOnStream:)] && self.audioStream) {
        [self.delegate setObserversOnStream:self.audioStream];
    }
    
    
    //Tell delegate that new song has been set
    if (self.delegate) {
        [self.delegate trackChangedToIndex:(int)self.selectedIndex];
    }
}

- (void)downloadTrack {
    NSLog(@"Download me to Play!");
    NSLog(@"%@", self.selectedTrack);
}


#pragma mark - AVAudioPlayer Delegate 

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self nextSong];
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"audioPlayerDecodeErrorDidOccur: %@", error);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"playState"]) {
        //If the stream has stopped then continue playing with next song
        SCAudioStreamState state = self.audioStream.playState;
        //NSLog(@"checking state: %d", state);
        switch (state) {
            case SCAudioStreamState_Stopped:
                 [self nextSong];
                break;
            case SCAudioStreamState_Playing:
                self.isBuffering = NO;
                break;
            default:
                break;
        }
    } /*else if ([keyPath isEqual:@"bufferState"]) {
        if (self.audioStream.bufferState == SCAudioStreamBufferState_NotBuffering) {
            
        }
    }*/
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
