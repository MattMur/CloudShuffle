//
//  SCSUtilities.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/20/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "SCSUtilities.h"
#import "TrackModel.h"

@implementation SCSUtilities

+ (NSString *)timeFormatted:(NSUInteger)totalMilliseconds
{
    int seconds = (totalMilliseconds / 1000) % 60; 
    int minutes = (totalMilliseconds / 60000) % 60; 
    int hours = (int)totalMilliseconds / 3600000;
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%d.%d.%02d",hours, minutes, seconds]; 
    } else {
        return [NSString stringWithFormat:@"%01d.%02d", minutes, seconds]; 
    }
    
}

+ (NSDictionary *)removeNullValuesFromDictionary:(NSDictionary *)dict 
{
    //filter null values
    NSMutableDictionary *filter = [NSMutableDictionary dictionaryWithDictionary:dict];
    for (NSString *key in dict) {
        if ([dict objectForKey:key] == [NSNull null]) {
            [filter removeObjectForKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:filter];
}

+ (NSArray*)tracksFromData:(NSData*)data
{
    //NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSError *error = nil;
    NSArray *trackData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    if (error != nil) {
        NSLog(@"An error occurred: %@", error);
        return nil;
    } else {
        //NSLog(@"tracks: %@", trackData.description);
        
        //Grab dictionaries out of trackData and wrap them in TrackModel objects
        NSMutableArray *tracksArray = [NSMutableArray arrayWithCapacity:[trackData count]];
        for (NSDictionary *trackDict in trackData) {
            TrackModel *track = [[TrackModel alloc] initWithDict:trackDict];
            
            // Only add track if streamable
            if (track.streamable) {
                [tracksArray addObject:track];
            }
        }
        
        return [NSArray arrayWithArray:tracksArray];
    }
}

+ (NSArray *)shuffleArray:(NSArray *)array 
{
    NSMutableArray *shuffledArray = [NSMutableArray arrayWithCapacity:array.count];
    NSMutableArray *helperArray = [NSMutableArray arrayWithArray:array];

    for (int i = 0; i < array.count; i++) {
        int random = (arc4random() % helperArray.count);
        
        [shuffledArray addObject: [helperArray objectAtIndex:random]];
        [helperArray removeObjectAtIndex:random];
   }
    return shuffledArray;
}

+ (NSString *)getImageUrlOfSize:(NSString *)sizeStr fromUrl:(NSString *)url
{
    url = [url stringByReplacingOccurrencesOfString:IMAGE_SIZE_LARGE withString:sizeStr];
    return url;
}

@end


@implementation UIColor (SCSUtilities)

+ (UIColor *)orangeTitleColor
{
    return [UIColor colorWithRed:235.0f/255.0f green:147.0f/255.0f blue:8.0f/255.0f alpha:1.0f];
}

+ (UIColor *)greybrownColor
{
    return [UIColor colorWithRed:183.0f/255.0f green:173.0f/255.0f blue:156.0f/255.0f alpha:1.0f];
}

@end
