DIST = dist
BUILD_DIR = $(shell swift build --show-bin-path 2>/dev/null || echo .build/debug)
RELEASE_BIN = $(shell swift build -c release --show-bin-path 2>/dev/null || echo .build/release)
BUNDLE_NAME = MDView_MDView.bundle
ICONS_SRC = MDView/Resources/Assets.xcassets/AppIcon.appiconset
APP = $(DIST)/MDView.app
VERSION = 1.0.0

.PHONY: build run clean app dmg

build:
	swift build
	@mkdir -p $(DIST)
	@cp $(BUILD_DIR)/MDView $(DIST)/
	@rm -rf $(DIST)/$(BUNDLE_NAME)
	@cp -R $(BUILD_DIR)/$(BUNDLE_NAME) $(DIST)/
	@echo "Built → $(DIST)/MDView"

run: build
	$(DIST)/MDView

app:
	@echo "==> Building release..."
	swift build -c release
	@echo "==> Generating AppIcon.icns..."
	@mkdir -p $(DIST)/AppIcon.iconset
	@cp $(ICONS_SRC)/icon_16x16.png     $(DIST)/AppIcon.iconset/icon_16x16.png
	@cp $(ICONS_SRC)/icon_32x32.png     $(DIST)/AppIcon.iconset/icon_16x16@2x.png
	@cp $(ICONS_SRC)/icon_32x32.png     $(DIST)/AppIcon.iconset/icon_32x32.png
	@cp $(ICONS_SRC)/icon_64x64.png     $(DIST)/AppIcon.iconset/icon_32x32@2x.png
	@cp $(ICONS_SRC)/icon_128x128.png   $(DIST)/AppIcon.iconset/icon_128x128.png
	@cp $(ICONS_SRC)/icon_256x256.png   $(DIST)/AppIcon.iconset/icon_128x128@2x.png
	@cp $(ICONS_SRC)/icon_256x256.png   $(DIST)/AppIcon.iconset/icon_256x256.png
	@cp $(ICONS_SRC)/icon_512x512.png   $(DIST)/AppIcon.iconset/icon_256x256@2x.png
	@cp $(ICONS_SRC)/icon_512x512.png   $(DIST)/AppIcon.iconset/icon_512x512.png
	@cp $(ICONS_SRC)/icon_1024x1024.png $(DIST)/AppIcon.iconset/icon_512x512@2x.png
	@iconutil -c icns -o $(DIST)/AppIcon.icns $(DIST)/AppIcon.iconset
	@rm -rf $(DIST)/AppIcon.iconset
	@echo "==> Creating app bundle..."
	@rm -rf $(APP)
	@mkdir -p $(APP)/Contents/MacOS
	@mkdir -p $(APP)/Contents/Resources
	@cp $(RELEASE_BIN)/MDView              $(APP)/Contents/MacOS/MDView
	@cp MDView/Resources/Info.plist        $(APP)/Contents/Info.plist
	@cp $(DIST)/AppIcon.icns                   $(APP)/Contents/Resources/AppIcon.icns
	@cp -R $(RELEASE_BIN)/$(BUNDLE_NAME)       $(APP)/$(BUNDLE_NAME)
	@echo "APPL????" > $(APP)/Contents/PkgInfo
	@echo "==> App bundle ready: $(APP)"

dmg: app
	@scripts/create-dmg.sh

clean:
	rm -rf $(DIST)
	swift package clean
