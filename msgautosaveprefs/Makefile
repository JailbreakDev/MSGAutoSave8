ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = MSGAutoSavePrefs
MSGAutoSavePrefs_FILES = MSGAutoSavePrefs.mm MSGAutoSaveMainHeaderView.m
MSGAutoSavePrefs_INSTALL_PATH = /Library/PreferenceBundles
MSGAutoSavePrefs_FRAMEWORKS = UIKit AdSupport AudioToolbox AVFoundation CoreGraphics CoreTelephony EventKit EventKitUI MessageUI StoreKit SystemConfiguration
MSGAutoSavePrefs_PRIVATE_FRAMEWORKS = Preferences
MSGAutoSavePrefs_LDFLAGS += -L./GoogleSDK/
MSGAutoSavePrefs_LIBRARIES = GoogleAdMobAds

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MSGAutoSavePrefs.plist$(ECHO_END)
