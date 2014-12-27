THEOS_DEVICE_IP = iPad
export TARGET = iphone:clang:8.1
ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = MSGAutoSave
MSGAutoSave_FILES = Tweak.xm BUIAlertView.m
MSGAutoSave_FRAMEWORKS = AssetsLibrary AVFoundation UIKit
MSGAutoSave_CFLAGS = -fobjc-arc

SUBPROJECTS += msgautosaveprefs

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 imagent MobileSMS"
