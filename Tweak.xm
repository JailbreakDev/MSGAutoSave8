#import <AssetsLibrary/AssetsLibrary.h>

@interface CKImageData : NSObject {
	NSData* _data;
}
@property (nonatomic,retain) NSData *data;
-(NSData *)data;
@end

@interface CKImageMediaObject : NSObject {
	CKImageData* _imageData;
}
@property (nonatomic, readonly) CKImageData * imageData;
-(id)generateThumbnail;
-(CKImageData *)imageData;
+(BOOL)isPreviewable;
@end

%hook CKImageMediaObject

-(id)generateThumbnail {

	id thumbnail = %orig;

	if (thumbnail) {

		ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		[library writeImageDataToSavedPhotosAlbum:(NSData *)[[self imageData] data] metadata:NULL completionBlock:^(NSURL *assetURL, NSError *error) {
                                 if (error != nil) {
                                     UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error: Can not save image to Camera Roll" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                                     [error show];
                                     [error release];
                                 } 
                                 [library release];
                             }];

	}

	return thumbnail;
}

%end