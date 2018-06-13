
#import <Foundation/Foundation.h>
#import "TrackModel.h"

@protocol ImageDownloaderDelegate;

@interface ImageDownloader : NSObject

+ (void)startDownloadForTrack:(TrackModel *)trackInfo withImageSize:(NSString *)size completion:(void (^)(UIImage *img))block;

@end
