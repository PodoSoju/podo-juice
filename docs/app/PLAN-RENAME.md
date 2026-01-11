# 프로젝트 명칭 변경 실행 계획

## 개요

| 현재 | 변경 후 | 설명 |
|------|--------|------|
| Soju (앱) | PodoSoju | macOS Wine 런처 앱 |
| PodoSoju (Wine) | Soju | Wine 배포판 |

## 사전 작업: 현재 변경사항 커밋

**커밋 1: 현재 상태 커밋/푸시**
```bash
git add -A
git commit -m "feat: Add AboutView, SettingsView and sync-project.py"
git push
```

---

## Phase 1: 파일/폴더 이름 변경

> **충돌 방지:** 이름이 교차되는 경우 `.bak` 중간 단계 사용

**커밋 2: SojuKit 매니저 파일 이름 변경**
```bash
# 1단계: .bak으로 임시 변경 (충돌 방지)
mv SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift \
   SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift.bak
mv SojuKit/Sources/SojuKit/Managers/PodoSojuDownloadManager.swift \
   SojuKit/Sources/SojuKit/Managers/PodoSojuDownloadManager.swift.bak

# 2단계: 최종 이름으로 변경
mv SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift.bak \
   SojuKit/Sources/SojuKit/Managers/SojuManager.swift
mv SojuKit/Sources/SojuKit/Managers/PodoSojuDownloadManager.swift.bak \
   SojuKit/Sources/SojuKit/Managers/SojuDownloadManager.swift

# 레거시 파일 삭제
rm SojuKit/Sources/SojuKit/Managers/WineManager.swift

git add -A
git commit -m "refactor: Rename PodoSoju managers to Soju managers"
```

**커밋 3: 앱 폴더 및 Xcode 프로젝트 이름 변경**
```bash
# 1단계: .bak으로 임시 변경 (충돌 방지)
mv Soju Soju.bak
mv Soju.xcodeproj Soju.xcodeproj.bak

# 2단계: 최종 이름으로 변경
mv Soju.bak PodoSoju
mv Soju.xcodeproj.bak PodoSoju.xcodeproj

# 3단계: 내부 파일 이름 변경
mv PodoSoju/SojuApp.swift PodoSoju/PodoSojuApp.swift
mv PodoSoju/Soju.entitlements PodoSoju/PodoSoju.entitlements

git add -A
git commit -m "refactor: Rename Soju app folder to PodoSoju"
```

---

## Phase 2: 소스 코드 내용 변경

**커밋 4: SojuKit 클래스/구조체 이름 변경**

파일: `SojuKit/Sources/SojuKit/Managers/SojuManager.swift`
- `PodoSojuManager` → `SojuManager`
- `PodoSojuVersion` → `SojuVersion`
- `PodoSojuError` → `SojuError`
- 설치 경로: `.appending(path: "PodoSoju")` → `.appending(path: "Soju")`

파일: `SojuKit/Sources/SojuKit/Managers/SojuDownloadManager.swift`
- `PodoSojuDownloadManager` → `SojuDownloadManager`
- `githubOwner = "yejune"` → `"PodoSoju"`
- `githubRepo = "podo-soju"` → `"soju"`
- `assetNamePattern = "PodoSoju"` → `"Soju"`

```bash
git add -A
git commit -m "refactor: Rename PodoSoju classes to Soju"
```

**커밋 5: Bundle ID 및 Logger subsystem 변경**

파일: `PodoSoju.xcodeproj/project.pbxproj`
- `PRODUCT_BUNDLE_IDENTIFIER = com.soju.app` → `com.podosoju.app`
- `INFOPLIST_KEY_CFBundleDisplayName = Soju` → `PodoSoju`

파일: `SojuKit/Sources/SojuKit/Extensions/Logger+SojuKit.swift`
- `subsystem: "com.soju.app"` → `"com.podosoju.app"`

파일: `SojuKit/Sources/SojuKit/Models/WorkspaceData.swift`
- `"com.soju.app"` → `"com.podosoju.app"`

파일: `SojuKit/Sources/SojuKit/Managers/SojuManager.swift`
- fallback ID: `"com.soju.app"` → `"com.podosoju.app"`

```bash
git add -A
git commit -m "refactor: Change bundle ID from com.soju.app to com.podosoju.app"
```

**커밋 6: 앱 소스 코드 참조 업데이트**

파일: `PodoSoju/PodoSojuApp.swift`
- `struct SojuApp` → `struct PodoSojuApp`
- `PodoSojuManager.shared` → `SojuManager.shared`

파일: `PodoSoju/ContentView.swift`
- `PodoSojuManager` → `SojuManager`
- `PodoSojuDownloadManager` → `SojuDownloadManager`

파일: `PodoSoju/Views/Settings/SettingsView.swift`
- `PodoSojuManager` → `SojuManager`
- `PodoSojuDownloadManager` → `SojuDownloadManager`

파일: `PodoSoju/Views/Settings/GraphicsSettingsView.swift`
- `PodoSojuManager` → `SojuManager`

파일: `PodoSoju/Views/Workspace/ShortcutView.swift`
- `PodoSojuManager` → `SojuManager`

```bash
git add -A
git commit -m "refactor: Update app source references to use Soju managers"
```

**커밋 7: SojuKit 모델 참조 업데이트**

파일: `SojuKit/Sources/SojuKit/Models/Workspace.swift`
- `PodoSojuManager` → `SojuManager`

파일: `SojuKit/Sources/SojuKit/Managers/WorkspaceManager.swift`
- `PodoSojuManager` → `SojuManager`

```bash
git add -A
git commit -m "refactor: Update SojuKit model references"
```

---

## Phase 3: 빌드 스크립트 업데이트

**커밋 8: sync-project.py 경로 업데이트**

파일: `Scripts/sync-project.py`
- `PROJECT_FILE = PROJECT_ROOT / "Soju.xcodeproj"` → `"PodoSoju.xcodeproj"`
- `SOJU_DIR = PROJECT_ROOT / "Soju"` → `"PodoSoju"`

```bash
git add -A
git commit -m "refactor: Update sync-project.py paths for PodoSoju"
```

---

## Phase 4: 문서 업데이트

**커밋 9: README.md 영문화**

```markdown
# PodoSoju

A Wine-based Windows application launcher for macOS.

## Features
- Workspace management for Windows applications
- Powered by Soju (Wine distribution)
- Native macOS experience with SwiftUI

## Requirements
- macOS 14.0+
- Apple Silicon (M1/M2/M3)

## Installation
Download from [Releases](https://github.com/PodoSoju/app/releases)

## License
MIT
```

```bash
git add -A
git commit -m "docs: Update README.md to English"
```

---

## Phase 5: 검증

**빌드 테스트**
```bash
python3 Scripts/sync-project.py
xcodebuild -scheme PodoSoju -configuration Debug build
```

**실행 테스트**
- 앱 실행 → PodoSoju.app
- Settings → Soju (Wine Distribution) 버전 확인
- Wine 다운로드 테스트 (GitHub: PodoSoju/soju)

---

## Phase 6: Git Remote 변경 (선택)

```bash
git remote set-url origin https://github.com/PodoSoju/app
git push -u origin main
```

---

## 변경 파일 목록

### 이름 변경 (6개)
1. `Soju/` → `PodoSoju/`
2. `Soju/SojuApp.swift` → `PodoSoju/PodoSojuApp.swift`
3. `Soju/Soju.entitlements` → `PodoSoju/PodoSoju.entitlements`
4. `Soju.xcodeproj/` → `PodoSoju.xcodeproj/`
5. `PodoSojuManager.swift` → `SojuManager.swift`
6. `PodoSojuDownloadManager.swift` → `SojuDownloadManager.swift`

### 삭제 (1개)
7. `SojuKit/.../WineManager.swift`

### 내용 수정 (14개+)
8. `PodoSoju.xcodeproj/project.pbxproj`
9. `PodoSoju/PodoSojuApp.swift`
10. `PodoSoju/ContentView.swift`
11. `PodoSoju/Views/Settings/SettingsView.swift`
12. `PodoSoju/Views/Settings/GraphicsSettingsView.swift`
13. `PodoSoju/Views/Workspace/ShortcutView.swift`
14. `SojuKit/.../SojuManager.swift`
15. `SojuKit/.../SojuDownloadManager.swift`
16. `SojuKit/.../Logger+SojuKit.swift`
17. `SojuKit/.../WorkspaceData.swift`
18. `SojuKit/.../Workspace.swift`
19. `SojuKit/.../WorkspaceManager.swift`
20. `Scripts/sync-project.py`
21. `README.md`

---

## 주의사항

1. **순서 중요:** 파일 이동 → 내용 수정 → 빌드 스크립트 → 빌드 테스트
2. **SojuKit 유지:** 프레임워크명은 변경하지 않음 (혼란 방지)
3. **단계별 커밋:** 각 단계마다 커밋하여 롤백 용이하게
4. **UI 텍스트 유지:** "PodoSoju", "About PodoSoju" 등 앱 UI는 유지
