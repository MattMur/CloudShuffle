//
//  BaseModel.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 1/1/12.
//  Copyright (c) 2012 SpecialOps Development. All rights reserved.
//

#import "BaseModel.h"
#import <Foundation/NSJSONSerialization.h>

@implementation BaseModel

@synthesize dict;

- (id)initWithJSONData:(NSData *)data
{
    if (self = [self init]) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        self.dict = jsonDict;
        
        if (self.dict == nil) {
            NSLog(@"An error occurred: %@", error);
        }
    }
    return self;
}

- (id)initWithDict:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        self.dict = dictionary;
    }
    return self;
}

- (NSString *)description {
    NSString *output = @"";
    if (self.dict) {
        NSArray *keys = [self.dict allKeys];
        NSArray *values = [self.dict allValues];
        
        for (int i = 0; i < self.dict.count; i++) {
            id value = [values objectAtIndex:i];
            output = [output stringByAppendingFormat:@"Key: %@    Value: %@\n", 
                      [keys objectAtIndex:i], 
                     value];
            
            //Check which objects are writeable to file
            /*NSString *writeable = @"NO";
            if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]] || 
                 [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] || 
                 [value isKindOfClass:[NSDate class]] || [value isKindOfClass:[NSNumber class]] ) {
                writeable = @"YES";
            }
            output = [output stringByAppendingFormat:@"Writeable = %@\n", writeable];*/
        }
    }
    return output;
}



@end
