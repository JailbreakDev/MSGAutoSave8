#import <Preferences/Preferences.h>
#import "GoogleSDK/GADBannerView.h"
#import "GoogleSDK/GADBannerViewDelegate.h"

@interface MSGAutoSavePrefsListController: PSListController <GADBannerViewDelegate>
@property(nonatomic, strong) GADBannerView *bannerView;
@end

@implementation MSGAutoSavePrefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"MSGAutoSavePrefs" target:self] retain];
	}
	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];
	self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
  	self.bannerView.delegate = self;
  	self.bannerView.adUnitID = @"ca-app-pub-4933765160729181/1539390357";
  	self.bannerView.rootViewController = self;
  	GADRequest *request = [GADRequest request];
  	request.gender = kGADGenderMale;
	[request setBirthdayWithMonth:6 day:18 year:1990];
	[request tagForChildDirectedTreatment:YES];
	request.contentURL = @"https://ioscoderz.com/forum/index.php";
	[request addKeyword:@"Messenger"];
	[request addKeyword:@"Whatsapp"];
	[request addKeyword:@"Apps"];
	[request addKeyword:@"Games"];
	[request addKeyword:@"Minecraft"];
	[request addKeyword:@"Football"];
	[request addKeyword:@"iOS"];
	[request addKeyword:@"GPS"];
	[request addKeyword:@"Communication"];
  	[self.bannerView loadRequest:request];
  	[self.bannerView setTranslatesAutoresizingMaskIntoConstraints:NO];
  	[[self view] addSubview:self.bannerView];
  	[[self view] addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:[self table] attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
  	[[self view] addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self view] attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
  	[[self view] addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[self table] attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
  	[[self view] addConstraint:[NSLayoutConstraint constraintWithItem:self.bannerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:100]];
}

-(NSArray *)getTitles:(PSSpecifier *)spec {
	return @[@"5%",@"10%",@"15%",@"20%",@"25%",@"30%",@"35%",@"40%",@"45%",@"50%",@"55%",@"60%",@"65%",@"70%",@"75%",@"80%",@"85%",@"90%",@"95%",@"Do not resize"];
}

-(NSArray *)getValues:(PSSpecifier *)spec {
	return @[@0.05,@0.1,@0.15,@0.2,@0.25,@0.3,@0.35,@0.4,@0.45,@0.5,@0.55,@0.6,@0.65,@0.7,@0.75,@0.8,@0.85,@0.9,@0.95,@1.0];
}

-(NSArray *)getVideoSizeTitles:(PSSpecifier *)spec {
    
    return @[@"Low Quality",@"Medium Quality",@"High Quality",@"Do not resize"];
}

-(NSArray *)getVideoSizeValues:(PSSpecifier *)spec {
    
    return @[@0,@1,@2,@-1];
}

@end

// vim:ft=objc
