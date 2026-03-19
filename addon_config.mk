meta:
	ADDON_NAME = ofxPoDoFo
	ADDON_DESCRIPTION = PoDoFo bindings for openFrameworks
	ADDON_AUTHOR = nariakiiwatani
	ADDON_TAGS = "pdf" "podofo"
	ADDON_URL = https://github.com/nariakiiwatani/ofxPoDoFo

common:
	ADDON_DEPENDENCIES += ofxClipper
	ADDON_INCLUDES += libs/PoDoFo/include
	ADDON_CPPFLAGS += -std=c++17

linux64:
	ADDON_LIBS += libs/PoDoFo/install/linux64/lib/libpodofo.a
	ADDON_LIBS += libs/PoDoFo/install/linux64/lib/libpodofo_private.a
	ADDON_LIBS += libs/PoDoFo/install/linux64/lib/libpodofo_3rdparty.a
	ADDON_LDFLAGS += -lssl -lcrypto -lxml2 -lpng -ljpeg -ltiff -lfontconfig -lfreetype -lz

linuxaarch64:
	ADDON_LIBS += libs/PoDoFo/install/linuxaarch64/lib/libpodofo.a
	ADDON_LIBS += libs/PoDoFo/install/linuxaarch64/lib/libpodofo_private.a
	ADDON_LIBS += libs/PoDoFo/install/linuxaarch64/lib/libpodofo_3rdparty.a
	ADDON_LDFLAGS += -lssl -lcrypto -lxml2 -lpng -ljpeg -ltiff -lfontconfig -lfreetype -lz

osx:
	ADDON_LIBS += libs/PoDoFo/install/osx/lib/libpodofo.a
	ADDON_LIBS += libs/PoDoFo/install/osx/lib/libpodofo_private.a
	ADDON_LIBS += libs/PoDoFo/install/osx/lib/libpodofo_3rdparty.a
	ADDON_LDFLAGS += -L/opt/homebrew/opt/openssl@3/lib -lssl -lcrypto -L/opt/homebrew/opt/libtiff/lib -ltiff -L/opt/homebrew/opt/jpeg-turbo/lib -ljpeg -lxml2 -L/opt/homebrew/opt/fontconfig/lib -lfontconfig -L/opt/homebrew/opt/freetype/lib -lfreetype -L/opt/homebrew/opt/libpng/lib -lpng16 -lz
