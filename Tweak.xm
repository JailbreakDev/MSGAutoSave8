#import <AssetsLibrary/AssetsLibrary.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.sharedroutine.msgautosave.plist"
static NSDictionary *settings;
static BOOL enabled = TRUE;
static float resizePercentage;
static ALAssetsLibrary* library;

@interface CKIMMessage : NSObject
-(id)parts;
@end

@interface CKMessagePart : NSObject
-(int)type;
@end

@interface CKMediaObject : NSObject
-(int)mediaType;
-(id)description;
-(id)data;
-(id)title;
-(id)subtitle;
-(id)mimeType;
-(id)previewItemURL;
-(id)fileURL;
@end

@interface CKImageData : NSObject
-(NSData *)data;
@end

@interface CKImageMediaObject : CKMediaObject
-(CKImageData *)imageData;
@end

@interface CKMovieMediaObject : CKMediaObject
-(void)setPxSize:(CGSize)arg1;
@end

@interface CKMediaObjectMessagePart : CKMessagePart
-(CKMediaObject *)mediaObject;
@end

@implementation UIImage (Resize) 
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();	
    UIGraphicsEndImageContext();
    return newImage;
}
@end

/*
%hook CKImageMediaObject

-(id)generateThumbnail {

	if (!enabled) return %orig;

	id thumbnail = %orig;

	if (thumbnail) {

		ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		UIImage *originalImage = [UIImage imageWithData:[[self imageData] data]];
		UIImage *resizedImage = [UIImage imageWithImage:originalImage scaledToSize:CGSizeMake(originalImage.size.width*resizePercentage,originalImage.size.height*resizePercentage)];
		NSData *resizedImageData = UIImageJPEGRepresentation(resizedImage,0.0);
		[library writeImageDataToSavedPhotosAlbum:(NSData *)resizedImageData metadata:NULL completionBlock:^(NSURL *assetURL, NSError *error) {
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
*/

void updateSettings(CFNotificationCenterRef center,
			   void * observer,
			   CFStringRef name,
			   const void * object,
			   CFDictionaryRef userInfo) {

	if (settings) {
		settings = nil;
		[settings release];
	}
	settings = [[NSDictionary alloc] initWithContentsOfFile:PLIST_PATH];
	enabled = settings[@"kEnabled"] ? [settings[@"kEnabled"] boolValue] : TRUE;
	resizePercentage = settings[@"kResizeValue"] ? (float)[settings[@"kResizeValue"] intValue]/100 : (float)1;
}

@interface MSGAutoSave : NSObject {

}
-(void)startListening;
@end

@implementation MSGAutoSave 

-(void)readAwesomeMessage:(NSNotification *)notif {

CKIMMessage *msg = notif.userInfo[@"CKMessageKey"];
for (CKMessagePart *msgPart in [msg parts]) {

if ([msgPart type] == 1) {

CKMediaObjectMessagePart *mediaPart = (CKMediaObjectMessagePart *)msgPart;
CKMediaObject *media = [mediaPart mediaObject];

if (media) {

if ([media mediaType] == 3) { //image

CKImageMediaObject *imageMedia = (CKImageMediaObject *)media;
NSData *imageData = [[imageMedia imageData] data];
UIImage *originalImage = [UIImage imageWithData:imageData];
UIImage *resizedImage = [UIImage imageWithImage:originalImage scaledToSize:CGSizeMake(originalImage.size.width*resizePercentage,originalImage.size.height*resizePercentage)];
NSData *resizedImageData = UIImageJPEGRepresentation(resizedImage,0.0);
[library writeImageDataToSavedPhotosAlbum:(NSData *)resizedImageData metadata:NULL completionBlock:^(NSURL *assetURL, NSError *error) {
				 if (error != nil) {
				     UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error: Can not save image to Camera Roll" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
				     [error show];
				     [error release];
				 } 
				 //[library release];
}];

} else if ([media mediaType] == 2) { //video

//CKMovieMediaObject *videoMedia = (CKMovieMediaObject *)media;

} else { //unknown

UIAlertView *error = [[UIAlertView alloc] initWithTitle:[media title] message:[NSString stringWithFormat:@"%@ (%d)",[media mimeType], [media mediaType]] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
[error show];
[error release];

}

}

}

      
}//for loop

}

-(void)startListening {

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAwesomeMessage:) name:@"CKConversationMessageReadNotification" object:nil];
}

@end

%ctor {

	library = [[ALAssetsLibrary alloc] init];
	MSGAutoSave *msgAutoSave = [[MSGAutoSave alloc] init];
	[msgAutoSave startListening];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateSettings, CFSTR("MSGAutoSaveUpdateSettingsNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	settings = [[NSDictionary alloc] initWithContentsOfFile:PLIST_PATH];
	resizePercentage = settings[@"kResizeValue"] ? (float)[settings[@"kResizeValue"] intValue]/100 : (float)1;
	enabled = settings[@"kEnabled"] ? [settings[@"kEnabled"] boolValue] : TRUE;
	if (enabled) {
		%init;
	}
}