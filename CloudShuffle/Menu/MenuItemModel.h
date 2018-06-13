//
//  MenuItemModel.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/18/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuItemModel : NSObject

@property (strong, nonatomic) UIImage *iconImage;
@property (strong, nonatomic) UIImage *iconImageHighlighted;
@property (strong, nonatomic) NSString *title;

@end
