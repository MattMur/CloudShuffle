//
//  MenuPopOverView.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 7/18/12.
//  Copyright (c) 2012 Usaa. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MenuPopOverView.h"
#import "MenuItemModel.h"

#define MENU_DEFAULT_HEIGHT 123.0f
#define CELL_DEFAULT_HEIGHT 50.0f

@implementation MenuPopOverView


- (void)reloadMenuItems
{
    [self.tableView reloadData];
}

#pragma mark - TableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_DEFAULT_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate) {
        [_delegate menu:self didSelectItemAtRow:indexPath.row];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numRows = (int)[self.dataSource count];
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        NSArray *fontArray = [UIFont fontNamesForFamilyName:@"Quicksand"];
        cell.textLabel.font = [UIFont fontWithName:[fontArray objectAtIndex:2] size:17];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menuCellPress"]];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    MenuItemModel *menuItem = [self.dataSource objectAtIndex:indexPath.row];
    //cell.imageView.image = menuItem.iconImage;
    //cell.imageView.highlightedImage = menuItem.iconImageHighlighted;
    cell.textLabel.text = menuItem.title;
    
    if (indexPath.row > 0) {
        UIImageView *seperator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"seperator"]];
        seperator.frame = CGRectMake(0, 0, cell.frame.size.width-20, seperator.frame.size.height);
        [cell addSubview:seperator];
    }
        
    return cell;
}

- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    
    //adjust height of containers based on number of cells
    NSUInteger numRows = dataSource.count;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, MENU_DEFAULT_HEIGHT + (CELL_DEFAULT_HEIGHT * (numRows-1) ));
}

- (void)drawRect:(CGRect)rect
{
    self.tableViewContainer.layer.cornerRadius = 8.0f;
    
    //create resizable background image
    UIImage *resizableImage = [self.backgroundImage.image resizableImageWithCapInsets:UIEdgeInsetsMake(79.0f, 0, 42.0f, 0) resizingMode:UIImageResizingModeStretch];
    self.backgroundImage.image = resizableImage;
}

@end
