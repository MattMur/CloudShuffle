//
//  PlaylistTableViewCell.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/9/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PlaylistTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) IBOutlet UIImageView *activeIndicator;
@property (strong, nonatomic) IBOutlet UILabel *playlistLabel;
@property (strong, nonatomic) IBOutlet UILabel *songCountLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

//background is applied based on even or odd row
- (void)setBackgroundImageForIndexPath:(NSIndexPath *)indexPath;

@end
