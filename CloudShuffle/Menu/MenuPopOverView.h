//
//  MenuPopOverView.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/18/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuPopOverView;

@protocol MenuPopOverViewDelegate <NSObject>

- (void)menu:(MenuPopOverView *)menuView didSelectItemAtRow:(NSUInteger)row;

@end

@interface MenuPopOverView : UIView <UITableViewDelegate, UITableViewDataSource> {
    UITableView *tableView_;
}

//Array of MenuItemModel
@property (strong, nonatomic) NSArray *dataSource;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *tableViewContainer;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) id<MenuPopOverViewDelegate> delegate;

- (void)reloadMenuItems;


@end
