#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.sharedroutine.msgautosave.plist"
static NSDictionary *settings;
static BOOL enabled = TRUE;
static BOOL confirmSave = FALSE;
static int resizeVideoValue = -1;
static float resizePercentage;
static ALAssetsLibrary *library;

@interface CKIMMessage : NSObject
-(NSArray *)parts;
@end

static CKIMMessage *receivedMessage = NULL;

@interface CKMessagePart : NSObject
-(int)type;
@end

@interface CKMediaObject : NSObject
-(int)mediaType;
-(id)description;
-(id)data;
-(NSString *)title;
-(NSString *)subtitle;
-(NSString *)mimeType;
-(NSURL *)fileURL;
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

@interface MSGAutoSave : NSObject <UIAlertViewDelegate> {

}
-(void)startListening;
@end

@implementation MSGAutoSave 

-(NSString *)qualityForValue:(int)value {

switch (value) {

case 0: //AVAssetExportPreset640x480
return AVAssetExportPreset640x480;
break;

case 1: //AVAssetExportPreset960x540
return AVAssetExportPreset960x540;
break;

case 2: //AVAssetExportPreset1280x720
return AVAssetExportPreset1280x720;
break;

case 3: //AVAssetExportPreset1920x1080
return AVAssetExportPreset1920x1080;
break;

default:
return @"not supported";
break;


}

}

-(void)saveVideoToCameraRollAtURL:(NSURL *)videoURL {

[library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {

if (error != nil) {
UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Can not save Video to Camera Roll: %@",error.description] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
[errorAlert show];
[errorAlert release];
} 

}];

}

-(void)processMessageParts:(NSArray *)parts {

for (CKMessagePart *msgPart in parts) {

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
				     UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Can not save Image to Camera Roll: %@\nPlease screenshot this and email the Developer",error.description] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
				     [errorAlert show];
				     [errorAlert release];
				 } 
}];

} else if ([media mediaType] == 2) { //video

NSURL *videoURL = [media fileURL];
AVAssetExportSession *exportSession = NULL;

if (resizeVideoValue == -1) {

[self saveVideoToCameraRollAtURL:videoURL];

} else {

AVAsset *asset = [AVAsset assetWithURL:videoURL];
NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
if (![compatiblePresets containsObject:[self qualityForValue:resizeVideoValue]]) {
	UIAlertView *notSupported = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Video Size not supported"] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
	[notSupported show];
	[notSupported release];
	return;
}

exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:[self qualityForValue:resizeVideoValue]];

if (exportSession) {

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{

    	NSString *fileName = [[videoURL absoluteString] lastPathComponent];
    	NSString *newName = [fileName stringByAppendingString:@"_resized.MOV"];
    	NSURL *fileURL = [videoURL URLByDeletingLastPathComponent];
    	fileURL = [fileURL URLByAppendingPathComponent:newName];
		exportSession.outputURL = fileURL;
    	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
      switch ([exportSession status]) {
	case AVAssetExportSessionStatusFailed:
	    break;
	case AVAssetExportSessionStatusCancelled:
	    break;
	default:
	    [self saveVideoToCameraRollAtURL:[exportSession outputURL]];
	    break;
      }
      [exportSession release];
    }];
   	 	dispatch_sync(dispatch_get_main_queue(), ^{
                 
      	});

    });
    
}

}

} else { //unknown

UIAlertView *error = [[UIAlertView alloc] initWithTitle:[media title] message:[NSString stringWithFormat:@"%@ (%d)\nPlease screenshot this and email the Developer",[media mimeType], [media mediaType]] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
[error show];
[error release];

}

}

}

      
}//for loop


}

-(void)readAwesomeMessage:(NSNotification *)notif {

CKIMMessage *msg = notif.userInfo[@"CKMessageKey"];

BOOL mediaAvailable = FALSE;

for (CKMessagePart *msgPart in [msg parts]) {

if ([msgPart type] == 1) {
mediaAvailable = TRUE;
}

}

if (confirmSave && mediaAvailable) {

receivedMessage = msg;
UIAlertView *confirmation = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:[NSString stringWithFormat:@"Do you want to save %lu Item(s)?",(unsigned long)[msg parts].count] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save",nil];
confirmation.tag = 99;
[confirmation show];
[confirmation release];

} else {

[self processMessageParts:[msg parts]];

}

}

-(void)startListening {
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAwesomeMessage:) name:@"CKConversationMessageReadNotification" object:nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

if (alertView.tag != 99) return;
if (alertView.cancelButtonIndex == buttonIndex) return;

if (receivedMessage) {
[self processMessageParts:[receivedMessage parts]];
}

}

-(void)dealloc {

	settings = nil;
	[settings release];
	library = nil;
	[library release];
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,CFSTR("MSGAutoSaveUpdateSettingsNotification"),NULL);
	[super dealloc];
}

@end

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
	resizeVideoValue = settings[@"kResizeVideoValue"] ? [settings[@"kResizeVideoValue"] intValue] : -1;
	confirmSave = [settings[@"kConfirmSave"] boolValue];
}

%ctor {

	settings = [[NSDictionary alloc] initWithContentsOfFile:PLIST_PATH];
	MSGAutoSave *msgAutoSave = [[[MSGAutoSave alloc] init] autorelease];
	[msgAutoSave startListening];
	library = [[ALAssetsLibrary alloc] init];
	resizePercentage = settings[@"kResizeValue"] ? (float)[settings[@"kResizeValue"] intValue]/100 : (float)1;
	resizeVideoValue = settings[@"kResizeVideoValue"] ? [settings[@"kResizeVideoValue"] intValue] : -1;
	enabled = settings[@"kEnabled"] ? [settings[@"kEnabled"] boolValue] : TRUE;
	confirmSave = [settings[@"kConfirmSave"] boolValue];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateSettings, CFSTR("MSGAutoSaveUpdateSettingsNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	
}