//
//  BaseModel.h
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseModel : NSObject

@property (nonatomic, strong) NSDictionary *dict;

- (id)initWithJSONData:(NSData *)data;
- (id)initWithDict:(NSDictionary *)dictionary;

@end
