# PodoSoju + PodoJuice 통합 빌드
# Usage: make build

.PHONY: build clean

DERIVED_DATA = $(HOME)/Library/Developer/Xcode/DerivedData/PodoSoju-hcwulptmfbevodfzrrgegncrwddn
APP_PATH = $(DERIVED_DATA)/Build/Products/Release/PodoSoju.app

# 기본 타겟
build:
	@echo "=== PodoJuice 빌드 ==="
	cd PodoJuice && swift build -c release
	@echo ""
	@echo "=== PodoSoju 빌드 ==="
	cd app && xcodebuild -project PodoSoju.xcodeproj -scheme PodoSoju -configuration Release build
	@echo ""
	@echo "=== PodoJuice 복사 ==="
	cp PodoJuice/.build/release/PodoJuice "$(APP_PATH)/Contents/Resources/"
	@echo ""
	@echo "=== 완료 ==="
	@ls -la "$(APP_PATH)/Contents/Resources/PodoJuice"

clean:
	cd PodoJuice && swift package clean
	cd app && xcodebuild -project PodoSoju.xcodeproj -scheme PodoSoju clean
