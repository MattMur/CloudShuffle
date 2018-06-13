//
//  InfoPanelView.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 8/2/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuicksandFontLabel.h"

@interface InfoPanelView : UIView
@property (strong, nonatomic) IBOutlet UIImageView *infoPanelImageView;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet QuicksandFontLabel *title;

@end
