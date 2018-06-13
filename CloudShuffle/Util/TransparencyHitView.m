//
//  TransparencyHitView.m
//  SoundCloudShuffle
//
//  Created by Matt Murray on 9/3/12.
//  Copyright (c) 2012 Special Ops Dev. All rights reserved.
//

#import "TransparencyHitView.h"

@implementation TransparencyHitView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Override to detect transparent pixels within subviews that are images
// Once we know that we can avoid hit detection on transparent pixels
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    if (view) {
        for (UIView *v in self.subviews){
            if ([v isKindOfClass:[UIImageView class]]) {
                
                //detect if the point selected is transparent
                UIImageView *im = (UIImageView *)v;
                unsigned char pixel[1] = {0};
                CGContextRef context = CGBitmapContextCreate(pixel,
                                                             1, 1, 8, 1, NULL,
                                                             kCGImageAlphaOnly);
                UIGraphicsPushContext(context);
                [im.image drawAtPoint:CGPointMake(-point.x, -point.y)];
                UIGraphicsPopContext();
                CGContextRelease(context);
                CGFloat alpha = pixel[0]/255.0;
                BOOL transparent = alpha < 0.01;
                
                //If point is transparent then set view to nil (enable touches on other views)
                if (transparent){
                    return nil;
                }
            }
            
        }
    }


    
    return view;
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
