#import <Preferences/Preferences.h>

@interface MSGAutoSavePrefsListController: PSListController {
}
@end

@implementation MSGAutoSavePrefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"MSGAutoSavePrefs" target:self] retain];
	}
	return _specifiers;
}

-(NSArray *)getTitles:(PSSpecifier *)spec {
	return @[@"5%",@"10%",@"15%",@"20%",@"25%",@"30%",@"35%",@"40%",@"45%",@"50%",@"55%",@"60%",@"65%",@"70%",@"75%",@"80%",@"85%",@"90%",@"95%",@"Do not resize"];
}

-(NSArray *)getValues:(PSSpecifier *)spec {
	return @[@5,@10,@15,@20,@25,@30,@35,@40,@45,@50,@55,@60,@65,@70,@75,@80,@85,@90,@95,@100];
}

-(NSArray *)getVideoSizeTitles:(PSSpecifier *)spec {
    
    return @[@"640x480",@"960x540",@"1280x720",@"1920x1080",@"Do not resize Videos"];
}

-(NSArray *)getVideoSizeValues:(PSSpecifier *)spec {
    
    return @[@0,@1,@2,@3,@-1];
}

@end

// vim:ft=objc
