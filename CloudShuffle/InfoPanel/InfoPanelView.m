//
//  InfoPanelView.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 8/2/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import "InfoPanelView.h"

@implementation InfoPanelView
@synthesize infoPanelImageView;
@synthesize closeButton;
@synthesize contentView;
@synthesize title;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
