//
//  TrackTableViewCell.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/10/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "TrackTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation TrackTableViewCell
@synthesize trackImageView;
@synthesize songNameLabel;
@synthesize artistNameLabel;
@synthesize activityIndicator;
@synthesize shadowContainer;

// Call this method when loading from nib
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        
        // Set seperator background for ios7
        [self setSelectionStyle:UITableViewCellSelectionStyleDefault];
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:0.33];
        bgColorView.layer.masksToBounds = YES;
        [self setSelectedBackgroundView:bgColorView];
    }
    return self;
}

- (id)init
{
    self = [super init];
    
   
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
//    self.songNameLabel.text = nil;
//    self.artistNameLabel.text = nil;
    self.trackImageView.image = nil;
    [self.activityIndicator stopAnimating];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
