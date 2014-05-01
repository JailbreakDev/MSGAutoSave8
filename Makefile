ARCHS = armv7 armv7s arm64
include theos/makefiles/common.mk

TWEAK_NAME = MSGAutoSave
MSGAutoSave_FILES = Tweak.xm
MSGAutoSave_FRAMEWORKS = UIKit AssetsLibrary AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk


