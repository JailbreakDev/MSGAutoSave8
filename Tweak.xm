#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "BUIAlertView.h"

@interface UIImage (Resize)
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
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

@interface NSDistributedNotificationCenter : NSNotificationCenter
+(id)defaultCenter;
-(void)postNotificationName:(id)arg1 object:(id)arg2 userInfo:(id)arg3 deliverImmediately:(BOOL)arg4 ;
-(void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4 ;
-(void)postNotificationName:(id)arg1 object:(id)arg2 userInfo:(id)arg3 ;
@end

@interface SBLaunchAppListener : NSObject
-(id)initWithBundleIdentifier:(id)arg1 handlerBlock:(/*^block*/id)arg2 ;
@end

@interface SBApplication : NSObject
-(BOOL)isRunning;
@end

@interface SBApplicationController : NSObject
+(id)sharedInstance;
-(SBApplication *)applicationWithBundleIdentifier:(id)b;
@end


@interface IMMessageItem : NSObject
@property (nonatomic,readonly) BOOL isRead;
@property (nonatomic,readonly) BOOL isFinished;
@property (nonatomic,readonly) BOOL isEmpty;
@property (nonatomic,retain) NSArray * fileTransferGUIDs;
@end

@interface FZMessage : IMMessageItem
@end

@interface IMFileTransfer : NSObject
@property (nonatomic,readonly) BOOL isFinished;
@property (assign,nonatomic) BOOL isIncoming; 
@property (nonatomic,retain) NSString * localPath;
@property (nonatomic,retain) NSString * type;
@property (nonatomic,retain) NSString * filename;
@property (nonatomic,retain) NSURL * localURL;
@property (assign,nonatomic) unsigned long long totalBytes;
@property (nonatomic,retain,readonly) NSString * mimeType;
@end

@interface IMFileTransferCenter : NSObject
+(id)sharedInstance;
-(IMFileTransfer *)transferForGUID:(NSString *)guid;
@end

@interface MSGAutoSaveSettings : NSObject
@property (nonatomic,readonly,getter=isEnabled) BOOL enabled;
@property (nonatomic,readonly,getter=shouldConfirmSave) BOOL confirmSave;
@property (nonatomic,readonly) CGFloat resizeImageValue;
@property (nonatomic,readonly) NSInteger resizeVideoValue;
@property (nonatomic,readonly) NSString *qualityFromSettings;
@property (nonatomic,copy) NSDictionary *settings;
+(instancetype)sharedSettings;
-(void)updateSettings;
-(NSString *)qualityForValue:(NSInteger)value;
@end

@implementation MSGAutoSaveSettings
@synthesize settings;

void settingsChanged(CFNotificationCenterRef center,
                           void * observer,
                           CFStringRef name,
                           const void * object,
                           CFDictionaryRef userInfo) {
  	[[MSGAutoSaveSettings sharedSettings] updateSettings];
}

+(instancetype)sharedSettings {
	static dispatch_once_t p = 0;

	__strong static MSGAutoSaveSettings *_sharedSettings = nil;

	dispatch_once(&p, ^{
		_sharedSettings = [[self alloc] init];
	});

	return _sharedSettings;
}

-(void)updateSettings {
	
	self.settings = nil;

	CFPreferencesAppSynchronize(CFSTR("com.sharedroutine.msgautosave"));
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.sharedroutine.msgautosave"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost) ?: CFArrayCreate(NULL, NULL, 0, NULL);
    self.settings = (__bridge_transfer NSDictionary *)CFPreferencesCopyMultiple(keyList,CFSTR("com.sharedroutine.msgautosave"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keyList);

}

-(instancetype)init {

	self = [super init];

	if (self) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("MSGAutoSaveUpdateSettingsNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		[self updateSettings];
	}

	return self;
}

-(BOOL)isEnabled {
	id value = self.settings[@"kEnabled"];
	return value ? [value boolValue] : TRUE;
}

-(BOOL)shouldConfirmSave {
	id value = self.settings[@"kConfirmSave"];
	return value ? [value boolValue] : FALSE;
}

-(CGFloat)resizeImageValue {
	id value = self.settings[@"kResizeValue"];
	return value ? (CGFloat)[value floatValue] : (CGFloat)-1.0;
}

-(NSInteger)resizeVideoValue {
	id value = self.settings[@"kResizeVideoValue"];
	return value ? [value integerValue] : -1;
}

-(NSString *)qualityForValue:(NSInteger)value {

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

-(NSString *)qualityFromSettings {
	return [self qualityForValue:self.resizeVideoValue];
}

@end

@interface MSGAutoSave : NSObject
-(void)autosaveInBackground;
+(instancetype)sharedInstance;
-(void)prepare;
@property (nonatomic,strong) NSArray *transferGUIDs;
@property (nonatomic,strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic,strong) SBLaunchAppListener *launchListener;
@property (nonatomic,readonly) NSString *processName;
@property (nonatomic,strong) AVAssetExportSession *exportSession;
@property (nonatomic,readonly) SBApplication *smsApplication;
@end

@implementation MSGAutoSave
@synthesize transferGUIDs,assetsLibrary,launchListener,exportSession;

+(instancetype)sharedInstance {
	static dispatch_once_t p = 0;

	__strong static MSGAutoSave *_sharedSelf = nil;

	dispatch_once(&p, ^{
		_sharedSelf = [[self alloc] init];
		_sharedSelf.assetsLibrary = [[ALAssetsLibrary alloc] init];
	});

	return _sharedSelf;
}

-(void)autosaveInBackground {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self autosave];
	});
}

//notification received both in SpringBoard and MobileSMS.
//When in MobileSMS - autosave
-(void)notificationReceived:(NSNotification *)notification {
	NSArray *fileTransferGUIDs = notification.userInfo[@"kTransferGUIDs"];
	[self setTransferGUIDs:fileTransferGUIDs];
	if ([self.processName isEqualToString:@"MobileSMS"]) {
		if (![MSGAutoSaveSettings sharedSettings].shouldConfirmSave) {
			[self autosaveInBackground];
		} else {
			dispatch_async(dispatch_get_main_queue(),^{
				BUIAlertView *av = [[BUIAlertView alloc] initWithTitle:@"Confirm Autosaving" message:[NSString stringWithFormat:@"Are you sure that you want to save %ld Files?",(long)fileTransferGUIDs.count] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
				[av showWithDismissBlock:^(UIAlertView *alertView, NSInteger buttonIndex, NSString *buttonTitle) {
		  			if (buttonIndex != alertView.cancelButtonIndex) {
		  				[self autosaveInBackground];
		  			} 
				}];
			});
		}
	}
}

-(void)prepare {

	if ([self.processName isEqualToString:@"SpringBoard"]) {
		//SpringBoard keeps the transferGUIDs until MobileSMS launches
		self.launchListener = [[%c(SBLaunchAppListener) alloc] initWithBundleIdentifier:@"com.apple.MobileSMS" handlerBlock:^{
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MSGAutoSaveDoYourThingNotification" object:nil userInfo:@{@"kTransferGUIDs":self.transferGUIDs} deliverImmediately:YES];
		}];

		if ([self.smsApplication isRunning]) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MSGAutoSaveDoYourThingNotification" object:nil userInfo:@{@"kTransferGUIDs":self.transferGUIDs} deliverImmediately:YES];
		}
	} 
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:@"MSGAutoSaveDoYourThingNotification" object:nil];
}

-(NSString *)processName {
	return [[NSProcessInfo processInfo] processName];
}

-(SBApplication *)smsApplication {
	return [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:@"com.apple.MobileSMS"];
}

-(BOOL)isImageMimeType:(NSString *)mimeType {
	return ([mimeType rangeOfString:@"image/"].location != NSNotFound);
}

-(BOOL)isVideoMimeType:(NSString *)mimeType {
	return ([mimeType rangeOfString:@"video/"].location != NSNotFound);
}

-(void)autosave {
	//Loop through the File Transfer IDs - In case someone send more files at a time

	void (^saveVideoAtURLBlock)(NSURL *videoURL) = ^(NSURL *videoURL) {
		//write video at url
		[self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
			if (error) {
				NSLog(@"[MSGAutoSave failed to save asset with error: %@]",error.description);
			}
		}];
	};

	for (NSString *guid in self.transferGUIDs) {
		IMFileTransfer *fileTransfer = [[%c(IMFileTransferCenter) sharedInstance] transferForGUID:guid];
		if (fileTransfer == nil) {
			continue; //skip this transfer, it is nil
		}
		[self.assetsLibrary assetForURL:fileTransfer.localURL resultBlock:^(ALAsset *asset) {
			//create an NSData object from the file URL
			NSData *fileData = [NSData dataWithContentsOfURL:fileTransfer.localURL];
			if ([self isImageMimeType:fileTransfer.mimeType] && fileData) { //is of type image
				UIImage *fileImage = [UIImage imageWithData:fileData]; //create image from the file data
				//resize image - if user does not want it ot be resized, the size is multiplied by 1.0 so it stays the same
				UIImage *resizedImage = [UIImage imageWithImage:fileImage scaledToSize:CGSizeMake(fileImage.size.width*[MSGAutoSaveSettings sharedSettings].resizeImageValue,fileImage.size.height*[MSGAutoSaveSettings sharedSettings].resizeImageValue)];
				//write to photo album
				[self.assetsLibrary writeImageToSavedPhotosAlbum:resizedImage.CGImage orientation:(ALAssetOrientation)[asset valueForProperty:ALAssetPropertyOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
					if (error) {
						NSLog(@"[MSGAutoSave failed to save asset with error: %@]",error.description);
					}
				}];
			} else if ([self isVideoMimeType:fileTransfer.mimeType] && fileData) { //is video type
				NSURL *videoURL = fileTransfer.localURL;
				AVAsset *videoAsset = [AVAsset assetWithURL:videoURL];

				//check if it is possible to resize or if resizing is requested by user
				NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
				if (![compatiblePresets containsObject:[[MSGAutoSaveSettings sharedSettings] qualityFromSettings]]) {
					NSLog(@"[MSGAutoSave %@]",[MSGAutoSaveSettings sharedSettings].resizeVideoValue == -1 ? @"Resize Value is set to -1. No resizing requested" : @"video presets not compatible with video");
					saveVideoAtURLBlock(videoURL);
					return;
				}
				self.exportSession = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:[[MSGAutoSaveSettings sharedSettings] qualityFromSettings]];
				self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
				self.exportSession.outputURL = videoURL;

				[self.exportSession exportAsynchronouslyWithCompletionHandler:^{
					if ([self.exportSession status] == AVAssetExportSessionStatusCompleted) {
						saveVideoAtURLBlock(self.exportSession.outputURL);
					} else {
						NSLog(@"[MSGAutoSave unexpected status: %ld]",(long)[self.exportSession status]);
					}
				}];
			}
		} failureBlock:^(NSError *error) {
			NSLog(@"[MSGAutoSave failed to get asset with error: %@]",error.description);
		}];
	}
}

@end

//hook imagent process to get when a message is being received. could not find a ChatKit notification that is posted :(
%group imagenthooks
%hook IMDServiceSession

- (void)didReceiveMessage:(FZMessage *)message forChat:(id)chat style:(unsigned char)style {
	%orig;

	if (message.isFinished && message.fileTransferGUIDs.count > 0) { //has any file to transfer
		//post to SpringBoard
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MSGAutoSaveDoYourThingNotification" object:nil userInfo:@{@"kTransferGUIDs":message.fileTransferGUIDs} deliverImmediately:YES];
	}
}

%end
%end

%ctor {
	NSString *processName = [[NSProcessInfo processInfo] processName];
	if ([MSGAutoSaveSettings sharedSettings].isEnabled) {
		if ([processName isEqualToString:@"SpringBoard"] || [processName isEqualToString:@"MobileSMS"]) {
			[[MSGAutoSave sharedInstance] prepare];
		} else if ([processName isEqualToString:@"imagent"]) {
			%init(imagenthooks);
		} 
	}
}