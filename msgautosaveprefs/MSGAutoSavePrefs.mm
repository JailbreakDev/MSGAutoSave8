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
	return @[@0.05,@0.1,@0.15,@0.20,@0.25,@0.30,@0.35,@0.40,@0.45,@0.50,@0.55,@0.60,@0.65,@0.70,@0.75,@0.80,@0.85,@0.90,@0.95,@1];
}
@end

// vim:ft=objc
