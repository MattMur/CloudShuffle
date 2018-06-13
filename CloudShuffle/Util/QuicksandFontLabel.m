//
//  QuicksandFontLabel.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/11/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import "QuicksandFontLabel.h"

@implementation QuicksandFontLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    NSArray *fontnames = [UIFont fontNamesForFamilyName:@"Quicksand"];
    //NSLog(@"fontname: %@", [fontnames objectAtIndex:2]);
    self.font = [UIFont fontWithName:[fontnames objectAtIndex:2] size:self.font.pointSize];
}

@end
