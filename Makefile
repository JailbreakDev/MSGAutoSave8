export TARGET = iphone:clang:9.0:8.0
ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = MSGAutoSave
MSGAutoSave_FILES = Tweak.xm
MSGAutoSave_FRAMEWORKS = Photos AVFoundation UIKit CoreImage CoreGraphics
MSGAutoSave_CFLAGS = -fobjc-arc

SUBPROJECTS += msgautosaveprefs

include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 imagent SpringBoard MobileSMS"
