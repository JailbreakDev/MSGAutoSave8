#import <AssetsLibrary/AssetsLibrary.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.sharedroutine.msgautosave.plist"
static NSDictionary *settings;
static BOOL enabled = TRUE;
static float resizePercentage;

@implementation UIImage (Resize) 
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}
@end

@interface CKImageData : NSObject {
	NSData* _data;
}
@property (nonatomic,retain) NSData *data;
-(NSData *)data;
@end

@interface CKImageMediaObject : NSObject <UIAlertViewDelegate> {
	CKImageData* _imageData;
}
@property (nonatomic, readonly) CKImageData * imageData;
-(id)generateThumbnail;
-(CKImageData *)imageData;
@end

%hook CKImageMediaObject

-(id)generateThumbnail {

	if (!enabled) return %orig;

	id thumbnail = %orig;

	if (thumbnail) {

		ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		UIImage *originalImage = [UIImage imageWithData:[[self imageData] data]];
		UIImage *resizedImage = [UIImage imageWithImage:originalImage scaledToSize:CGSizeMake(originalImage.size.width*resizePercentage,originalImage.size.height*resizePercentage)];
		NSData *resizedImageData = UIImagePNGRepresentation(resizedImage);
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
	resizePercentage = settings[@"kResizeValue"] ? [settings[@"kResizeValue"] floatValue] : 1.0;
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateSettings, CFSTR("MSGAutoSaveUpdateSettingsNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	settings = [[NSDictionary alloc] initWithContentsOfFile:PLIST_PATH];
	resizePercentage = settings[@"kResizeValue"] ? [settings[@"kResizeValue"] floatValue] : 1.0;
	enabled = settings[@"kEnabled"] ? [settings[@"kEnabled"] boolValue] : TRUE;
	if (enabled) {
		%init;
	}
}