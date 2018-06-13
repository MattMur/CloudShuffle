//
//  TrackTableViewCell.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/10/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrackTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *trackImageView;
@property (strong, nonatomic) IBOutlet UILabel *songNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *shadowContainer;

@end
