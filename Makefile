DIST = dist
BUILD_DIR = $(shell swift build --show-bin-path)
BUNDLE_NAME = SimpleEdit_SimpleEdit.bundle

.PHONY: build clean

build:
	swift build
	mkdir -p $(DIST)
	cp $(BUILD_DIR)/SimpleEdit $(DIST)/
	rm -rf $(DIST)/$(BUNDLE_NAME)
	cp -R $(BUILD_DIR)/$(BUNDLE_NAME) $(DIST)/

clean:
	rm -rf $(DIST)
	swift package clean
