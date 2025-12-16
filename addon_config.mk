meta:
	ADDON_NAME = ofxPoDoFo
	ADDON_AUTHOR = nariakiiwatani
	ADDON_URL = https://github.com/nariakiiwatani/ofxPoDoFo

common:
	# https://github.com/nariakiiwatani/ofxClipper
	ADDON_DEPENDENCIES = ofxClipper

linux64:
	# Static PoDoFo built into libs/PoDoFo via scripts/build_podofo.sh
	ADDON_INCLUDES += $(OF_ADDON_PATH)/libs/PoDoFo/include
	# Explicit static libs from the staged install to avoid linker ordering issues.
	ADDON_LDFLAGS += -Wl,--start-group $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/linux64/lib/libpodofo.a $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/linux64/lib/libpodofo_private.a $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/linux64/lib/libpodofo_3rdparty.a -Wl,--end-group
	ADDON_LDFLAGS += -lssl -lcrypto -lxml2 -lpng -ljpeg -ltiff -lfontconfig -lfreetype -lz

osx:
	# Static PoDoFo built into libs/PoDoFo via scripts/build_podofo.sh
	ADDON_INCLUDES += $(OF_ADDON_PATH)/libs/PoDoFo/include
	ADDON_LDFLAGS = $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/osx/lib/libpodofo.a $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/osx/lib/libpodofo_private.a $(OF_ROOT)/addons/ofxPoDoFo/libs/PoDoFo/install/osx/lib/libpodofo_3rdparty.a
	# Add Homebrew lib path and libs
	ADDON_LDFLAGS += -L$(shell brew --prefix openssl@3)/lib -lssl -lcrypto -L$(shell brew --prefix libtiff)/lib -ltiff -L$(shell brew --prefix jpeg-turbo)/lib -ljpeg -lxml2 -L$(shell brew --prefix fontconfig)/lib -lfontconfig -L$(shell brew --prefix freetype)/lib -lfreetype -L$(shell brew --prefix libpng)/lib -lpng16 -lz
	ADDON_CPPFLAGS = -std=c++17
	ADDON_LDFLAGS += -mmacosx-version-min=13.2
	ADDON_POST_BUILD_STEP = install_name_tool -change /opt/homebrew/opt/libpng/lib/libpng16.16.dylib @rpath/libpng16.16.dylib "$(PROJECT_TARGET)"
	# System deps; adjust if your Homebrew prefixes differ.
	ADDON_LIBS =
	ADDON_LIB_PATHS =