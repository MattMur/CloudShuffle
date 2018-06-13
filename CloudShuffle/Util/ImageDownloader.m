
#import "ImageDownloader.h"
#import "SCSUtilities.h"

@implementation ImageDownloader

+ (void)startDownloadForTrack:(TrackModel *)trackInfo withImageSize:(NSString *)size completion:(void (^)(UIImage *img))block
{
    NSString *downloadString;
    if (![trackInfo.artwork_url isEqual:[NSNull null]]) {
        downloadString = trackInfo.artwork_url;
    } else if (![trackInfo.artist.avatar_url isEqual:[NSNull null]]) {
        downloadString = trackInfo.artist.avatar_url;
    } else {
        block(nil);
    }
    
    downloadString = [SCSUtilities getImageUrlOfSize:size fromUrl:downloadString];
    NSURL *imgUrl = [NSURL URLWithString:downloadString];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *img = [UIImage imageWithData:[NSData dataWithContentsOfURL:imgUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(img);
        });
    });
}


@end



