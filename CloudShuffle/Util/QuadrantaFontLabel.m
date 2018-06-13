//
//  QuadrantaFontLabel.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/10/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import "QuadrantaFontLabel.h"

@implementation QuadrantaFontLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    NSArray *fontnames = [UIFont fontNamesForFamilyName:@"Quadranta"];
    //NSLog(@"fontname: %@", fontnames);
    self.font = [UIFont fontWithName:[fontnames objectAtIndex:0] size:self.font.pointSize];
}

@end
