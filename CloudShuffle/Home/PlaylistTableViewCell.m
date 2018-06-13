//
//  PlaylistTableViewCell.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/9/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import "PlaylistTableViewCell.h"


@implementation PlaylistTableViewCell
@synthesize backgroundImage;
@synthesize activeIndicator;
@synthesize playlistLabel;
@synthesize songCountLabel;
@synthesize activityIndicator;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

/*- (void) animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
	//CAKeyframeAnimation *keyframeAnimation = (CAKeyframeAnimation*)animation;
	//[self.layer setValue:[NSNumber numberWithInt:160] forKeyPath:keyframeAnimation.keyPath];
	[self.layer removeAllAnimations];
}*/

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted) {
        [UIView animateWithDuration:0.07f animations:^{
            self.frame = CGRectOffset(self.frame, 2.0f, 4.0f);
        }];
    } else {
        [UIView animateWithDuration:0.33f animations:^{
            self.frame = CGRectOffset(self.frame, -2.0f, -4.0f);
        }];
    }
    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    self.activeIndicator.highlighted = NO;
    if (!self.activityIndicator.isAnimating) {
        self.activeIndicator.highlighted = selected;
    }
    
}

- (void)setBackgroundImageForIndexPath:(NSIndexPath *)indexPath
{
    UIImage *backgroundImg = nil;
    
    //background is applied based on even or odd row
    if (indexPath.row % 2 == 0) {
        backgroundImg = [[UIImage imageNamed:@"homePlaylist1"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 123.0f, 0, 80.0f) resizingMode:UIImageResizingModeStretch];
    } else {
        backgroundImg = [[UIImage imageNamed:@"homePlaylist2"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 80.0f, 0, 123.0f) resizingMode:UIImageResizingModeStretch];
    }
    [self.backgroundImage setImage:backgroundImg];
    
    // Add parallax
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-15);
    horizontalMotionEffect.maximumRelativeValue = @(15);
    [self addMotionEffect:horizontalMotionEffect];
    
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-20);
    verticalMotionEffect.maximumRelativeValue = @(20);
    [self addMotionEffect:verticalMotionEffect];
}


@end
