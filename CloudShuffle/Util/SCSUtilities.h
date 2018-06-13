//
//  SCSUtilities.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/20/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IMAGE_SIZE_ORIGINAL @"original"
#define IMAGE_SIZE_SMALL @"small"
#define IMAGE_SIZE_LARGE @"large"
#define IMAGE_SIZE_BADGE @"badge"

@interface SCSUtilities : NSObject

+ (NSString *)timeFormatted:(NSUInteger)totalMilliseconds;
+ (NSDictionary *)removeNullValuesFromDictionary:(NSDictionary *)dict;
+ (NSArray *)tracksFromData:(NSData*)data;
+ (NSArray *)shuffleArray:(NSArray *)array;
+ (NSString *)getImageUrlOfSize:(NSString *)sizeStr fromUrl:(NSString *)url;
@end

@interface UIColor (SCSUtilities)

+ (UIColor *)orangeTitleColor;
+ (UIColor *)greybrownColor;

@end