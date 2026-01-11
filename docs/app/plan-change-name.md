프로젝트 명칭 전면 변경 계획

 참고: 이 계획은 plan-change-name.md로 프로젝트 루트에 저장됨

 목표
 ┌────────────────────────┬──────────────────────────┬────────────────────┐
 │          현재          │         변경 후          │        설명        │
 ├────────────────────────┼──────────────────────────┼────────────────────┤
 │ Soju (앱)              │ PodoSoju                 │ macOS Wine 런처 앱 │
 ├────────────────────────┼──────────────────────────┼────────────────────┤
 │ PodoSoju (Wine)        │ Soju                     │ Wine 배포판        │
 ├────────────────────────┼──────────────────────────┼────────────────────┤
 │ github.com/yejune/soju │ github.com/PodoSoju/app  │ 앱 저장소          │
 ├────────────────────────┼──────────────────────────┼────────────────────┤
 │ (없음)                 │ github.com/PodoSoju/soju │ Wine 배포판 저장소 │
 └────────────────────────┴──────────────────────────┴────────────────────┘
 ---
 Phase 1: 디렉토리/파일명 변경

 1.1 앱 폴더

 Soju/ → PodoSoju/
 ├── SojuApp.swift → PodoSojuApp.swift
 ├── Soju.entitlements → PodoSoju.entitlements
 └── (나머지 유지)

 1.2 Xcode 프로젝트

 Soju.xcodeproj/ → PodoSoju.xcodeproj/

 1.3 SojuKit 내 파일

 SojuKit/Sources/SojuKit/Managers/
 ├── PodoSojuManager.swift → SojuManager.swift
 ├── PodoSojuDownloadManager.swift → SojuDownloadManager.swift
 └── WineManager.swift → (삭제 - 레거시)

 ---
 Phase 2: 소스 코드 변경

 2.1 클래스/구조체/열거형 이름
 ┌─────────────────────────┬─────────────────────┬───────────────────────────┐
 │          현재           │       변경 후       │           파일            │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ PodoSojuManager         │ SojuManager         │ SojuManager.swift         │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ PodoSojuDownloadManager │ SojuDownloadManager │ SojuDownloadManager.swift │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ PodoSojuVersion         │ SojuVersion         │ SojuManager.swift         │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ PodoSojuError           │ SojuError           │ SojuManager.swift         │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ GPTKInstallationStatus  │ (유지)              │ SojuManager.swift         │
 ├─────────────────────────┼─────────────────────┼───────────────────────────┤
 │ D3DMetalError           │ (유지)              │ SojuManager.swift         │
 └─────────────────────────┴─────────────────────┴───────────────────────────┘
 2.2 번들 ID 및 설정
 ┌──────────────────┬──────────────┬──────────────────┐
 │       항목       │     현재     │     변경 후      │
 ├──────────────────┼──────────────┼──────────────────┤
 │ Bundle ID        │ com.soju.app │ com.podosoju.app │
 ├──────────────────┼──────────────┼──────────────────┤
 │ Display Name     │ Soju         │ PodoSoju         │
 ├──────────────────┼──────────────┼──────────────────┤
 │ Logger subsystem │ com.soju.app │ com.podosoju.app │
 └──────────────────┴──────────────┴──────────────────┘
 변경 파일:
 - PodoSoju.xcodeproj/project.pbxproj
 - SojuKit/Sources/SojuKit/Extensions/Logger+SojuKit.swift
 - SojuKit/Sources/SojuKit/Managers/SojuManager.swift (fallback ID)
 - SojuKit/Sources/SojuKit/Models/WorkspaceData.swift

 2.3 GitHub 저장소 설정

 SojuDownloadManager.swift:
 // 현재
 private let githubOwner = "yejune"
 private let githubRepo = "podo-soju"
 private let assetNamePattern = "PodoSoju"

 // 변경 후
 private let githubOwner = "PodoSoju"
 private let githubRepo = "soju"
 private let assetNamePattern = "Soju"

 2.4 설치 경로

 SojuManager.swift:
 // 현재
 .appending(path: "Libraries")
 .appending(path: "PodoSoju")

 // 변경 후
 .appending(path: "Libraries")
 .appending(path: "Soju")

 2.5 UI 텍스트 변경

 PodoSojuApp.swift:
 - 🍇 PodoSoju app launched (유지)
 - About PodoSoju (유지)
 - 👋 PodoSoju app terminated (유지)

 AboutView.swift:
 // 변경 후
 Text("PodoSoju")  // 앱 이름
 Text("PodoSoju is a Wine-based Windows application launcher for macOS.")
 Text("Powered by Soju (Wine distribution)")  // Wine 배포판 설명

 SettingsView.swift:
 - SojuSettingsView 내 Soju (Wine Distribution) 섹션 - Wine 배포판 설정

 ---
 Phase 3: Whisky 참조 정리

 3.1 삭제할 파일

 - SojuKit/Sources/SojuKit/Managers/WineManager.swift (레거시, 미사용)

 3.2 정리할 주석

 코드 내 "Whisky pattern" 주석은 구현 참고 기록으로 유지
 (동작 참조만 했고 코드 복사 없음)

 3.3 문서 파일

 *.md 파일의 Whisky 참조는 유지 (기술 조사 기록)

 ---
 Phase 4: Git 저장소 및 폴더 변경

 4.1 로컬 작업 폴더 이름 변경

 mv ~/Work/soju ~/Work/podosoju

 4.2 로컬 remote 변경

 cd ~/Work/podosoju
 git remote set-url origin https://github.com/PodoSoju/app

 4.2 sync-project.py 업데이트

 프로젝트명 변경에 맞춰 스크립트 경로 수정

 ---
 Phase 5: 멱등 빌드 스크립트 업데이트

 scripts/sync-project.py 변경:
 - PROJECT_FILE 경로: PodoSoju.xcodeproj
 - SOJU_DIR 경로: PodoSoju/

 ---
 변경 파일 목록 (총 20+ 파일)

 이름 변경 (mv)

 1. Soju/ → PodoSoju/
 2. Soju/SojuApp.swift → PodoSoju/PodoSojuApp.swift
 3. Soju/Soju.entitlements → PodoSoju/PodoSoju.entitlements
 4. Soju.xcodeproj/ → PodoSoju.xcodeproj/
 5. SojuKit/.../PodoSojuManager.swift → SojuManager.swift
 6. SojuKit/.../PodoSojuDownloadManager.swift → SojuDownloadManager.swift

 삭제

 7. SojuKit/.../WineManager.swift

 내용 수정

 8. PodoSoju.xcodeproj/project.pbxproj
 9. PodoSoju/PodoSojuApp.swift
 10. PodoSoju/Views/AboutView.swift
 11. PodoSoju/Views/Settings/SettingsView.swift
 12. PodoSoju/ContentView.swift
 13. SojuKit/.../SojuManager.swift
 14. SojuKit/.../SojuDownloadManager.swift
 15. SojuKit/.../Logger+SojuKit.swift
 16. SojuKit/.../WorkspaceData.swift
 17. SojuKit/.../Workspace.swift
 18. SojuKit/.../WorkspaceManager.swift
 19. SojuKit/.../GraphicsBackend.swift
 20. scripts/sync-project.py
 21. scripts/test-podosoju.swift
 22. README.md (영문 재작성)

 ---
 검증

 빌드 테스트

 cd ~/Work/soju
 python3 scripts/sync-project.py  # 프로젝트 동기화
 xcodebuild -scheme PodoSoju -configuration Debug build

 Git 테스트

 git remote -v  # PodoSoju/app 확인

 실행 테스트

 - 앱 실행 → PodoSoju.app
 - Settings → Soju (Wine Distribution) 버전 확인
 - Wine 다운로드 → github.com/PodoSoju/soju에서 다운로드

 ---
 Phase 6: 문서 영문화

 6.1 README.md (영문 작성)

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

 6.2 릴리즈 노트 (영문)

 GitHub Releases 작성 시 영문 사용:
 - PodoSoju/app: PodoSoju 앱 릴리즈 (영문)
 - PodoSoju/soju: Soju Wine 배포판 릴리즈 (영문)

 ---
 주의사항

 1. 순서 중요: 파일 이동 → 내용 수정 → 빌드 스크립트 → 빌드 테스트
 2. SojuKit 유지: 프레임워크명은 변경하지 않음 (혼란 방지)
 3. 한 번에 커밋: 모든 변경을 하나의 커밋으로 (일관성)
 4. 영문 문서: README.md 및 모든 릴리즈 노트는 영문으로 작성

 ---
 실행 순서

 1. 계획 저장: plan-change-name.md로 루트에 저장
 2. 파일/폴더 이름 변경: mv 명령으로 순차 실행
 3. 내용 수정: 코드 내 참조 업데이트
 4. 빌드 스크립트 수정: sync-project.py 경로 업데이트
 5. 빌드 테스트: python3 scripts/sync-project.py
 6. Git remote 변경: git remote set-url origin ...
 7. 로컬 폴더 이름 변경: mv ~/Work/soju ~/Work/podosoju
 8. 커밋 & 푸시

