# PodoSoju Wine 11.0-rc4 통합 완료

## 개요

Soju에 PodoSoju Wine 11.0-rc4를 성공적으로 통합했습니다.

**PodoSoju란?**
- Wine (Windows 에뮬레이터)의 대체 구현
- Gcenx Wine-Staging 11.0-rc4 + D3DMetal (GPTK) 기반
- macOS 네이티브 실행 최적화

---

## 완료된 작업

### 1. PodoSoju 패키징

**위치:** `/Users/max/Work/podo-soju`

**스크립트:** `scripts/package.sh`

**결과물:**
- `dist/PodoSoju-11.0-rc4.tar.gz` (336MB)
- Wine 11.0-rc4 (Staging) + D3DMetal 포함
- 버전 정보: `PodoSojuVersion.plist`

**패키징 내용:**
```
Libraries/
├── PodoSoju/
│   ├── bin/           # wine, wineboot, wineserver 등
│   ├── lib/           # Wine 라이브러리 + D3DMetal.framework
│   └── share/         # Wine 리소스
└── PodoSojuVersion.plist  # 버전 정보 (11.0.0-rc4+staging)
```

### 2. SojuKit - PodoSojuManager 구현

**파일:** `SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift`

**기능:**
- ✅ PodoSoju 바이너리 경로 관리
- ✅ Wine 환경 변수 자동 설정 (WINEPREFIX, WINEDEBUG 등)
- ✅ 프로세스 실행 관리 (wine, wineboot, wineserver)
- ✅ 버전 정보 로드 (`PodoSojuVersion.plist`)
- ✅ Workspace 초기화 (`wineboot --init`)

**주요 메서드:**
```swift
// Singleton 인스턴스
PodoSojuManager.shared

// Wine 환경 변수 생성
.constructEnvironment(for: workspace)

// Wine 프로세스 실행
.runWine(args: [String], workspace: Workspace) -> AsyncStream<ProcessOutput>

// wineboot 실행 (prefix 초기화)
.runWineboot(workspace: Workspace) async throws

// Workspace 초기화
.initializeWorkspace(_ workspace: Workspace) async throws
```

### 3. Workspace-PodoSoju 연결

**파일:** `SojuKit/Sources/SojuKit/Models/Workspace.swift`

**변경사항:**
```swift
// Wine 환경 변수 (PodoSojuManager 사용)
public func wineEnvironment() -> [String: String]

// Wine prefix 초기화
public func initializeWinePrefix() async throws

// Program 실행 (PodoSojuManager 통합)
Program.run(in: Workspace) async throws
```

### 4. 설치 완료

**설치 위치:**
```
~/Library/Application Support/com.soju.app/Libraries/
├── PodoSoju/
│   ├── bin/wine          # wine 바이너리 (Mach-O x86_64)
│   ├── bin/wineserver    # wineserver
│   ├── bin/wineboot      # wineboot
│   └── lib/              # 라이브러리 (D3DMetal 포함)
└── PodoSojuVersion.plist # 버전 정보
```

**검증:**
```bash
$ arch -x86_64 ~/Library/Application\ Support/com.soju.app/Libraries/PodoSoju/bin/wine --version
wine-11.0-rc4 (Staging)
```

---

## 빌드 결과

### SojuKit 빌드

```bash
cd /Users/max/Work/Soju/SojuKit
swift build
```

**결과:** ✅ Build complete! (1.55s)

### Soju 앱 빌드

```bash
cd /Users/max/Work/Soju
xcodebuild -scheme Soju -configuration Debug build
```

**결과:** ✅ BUILD SUCCEEDED

---

## 사용 방법

### 1. Workspace 생성 및 초기화

```swift
import SojuKit

// Workspace 생성
let workspaceURL = URL(fileURLWithPath: "~/Documents/Workspaces/MyWorkspace")
let workspace = Workspace(workspaceUrl: workspaceURL)

// Wine prefix 초기화
try await workspace.initializeWinePrefix()
```

### 2. Wine 프로그램 실행

```swift
// 프로그램 생성
let program = Program(
    name: "notepad.exe",
    url: workspace.winePrefixURL.appending(path: "windows/system32/notepad.exe")
)

// 실행
try await program.run(in: workspace)
```

### 3. 수동 Wine 명령 실행

```swift
let podoSoju = PodoSojuManager.shared

// wine --version
for await output in try podoSoju.runWine(args: ["--version"], workspace: workspace) {
    switch output {
    case .message(let message):
        print(message)
    case .error(let error):
        print("ERROR: \(error)")
    case .terminated(let code):
        print("Exited with code: \(code)")
    case .started:
        print("Started")
    }
}
```

---

## 테스트 결과

**테스트 스크립트:** `Scripts/test-podosoju.swift`

```bash
$ ./Scripts/test-podosoju.swift

=== PodoSoju 설치 확인 ===
PodoSoju Path: ~/Library/Application Support/com.soju.app/Libraries/PodoSoju
Wine Binary: ~/Library/Application Support/com.soju.app/Libraries/PodoSoju/bin/wine
✅ PodoSoju 설치 확인
✅ 실행 권한 확인
✅ PodoSoju 버전: 11.0.0-rc4+staging

=== wine --version 테스트 ===
✅ Wine 버전: wine-11.0-rc4 (Staging)
✅ 모든 테스트 성공
```

---

## 향후 작업

### 우선순위 높음

1. **wineboot 초기화 테스트**
   - 실제 Wine prefix 생성 테스트
   - drive_c 구조 확인
   - 레지스트리 생성 확인

2. **프로그램 실행 테스트**
   - 간단한 .exe 파일 실행 (notepad.exe)
   - 환경 변수 올바르게 전달되는지 확인
   - 프로세스 출력 스트림 동작 확인

3. **오류 처리 강화**
   - Wine 실행 실패 시 명확한 에러 메시지
   - 로그 파일 생성 및 관리
   - 크래시 복구 전략

### 우선순위 중간

4. **DXVK 통합**
   - DXVK 라이브러리 설치
   - DLL 교체 로직 구현
   - DirectX 게임 실행 테스트

5. **성능 최적화**
   - Wine 프로세스 재사용
   - wineserver 관리 (자동 종료/재시작)
   - 메모리 사용량 모니터링

6. **UI 통합**
   - Workspace 생성 마법사
   - 프로그램 설치 UI
   - 실행 중인 프로그램 모니터링

### 우선순위 낮음

7. **고급 기능**
   - Winetricks 통합
   - 커스텀 DLL 오버라이드
   - Windows 버전 설정
   - 디스플레이 설정 (해상도, DPI)

---

## 기술 상세

### PodoSojuManager 아키텍처

```
PodoSojuManager (Singleton)
├── 경로 관리
│   ├── podoSojuRoot: ~/Library/Application Support/com.soju.app/Libraries/PodoSoju
│   ├── binFolder: .../bin
│   ├── libFolder: .../lib
│   ├── wineBinary: .../bin/wine
│   ├── wineserverBinary: .../bin/wineserver
│   └── winebootBinary: .../bin/wineboot
│
├── 환경 변수 생성
│   ├── WINEPREFIX (Workspace 경로)
│   ├── WINEDEBUG=fixme-all
│   ├── GST_DEBUG=1
│   └── Workspace 커스텀 환경변수
│
└── 프로세스 관리
    ├── runWine() -> AsyncStream<ProcessOutput>
    ├── runWineboot() async throws
    └── runWineserver() -> AsyncStream<ProcessOutput>
```

### ProcessOutput 타입

```swift
public enum ProcessOutput {
    case started                    // 프로세스 시작
    case message(String)            // stdout 메시지
    case error(String)              // stderr 메시지
    case terminated(Int32)          // 프로세스 종료 (exit code)
}
```

### 버전 정보 구조

```swift
public struct PodoSojuVersion: Codable {
    public let major: Int           // 11
    public let minor: Int           // 0
    public let patch: Int           // 0
    public let preRelease: String?  // "rc4"
    public let build: String?       // "staging"

    // versionString: "11.0.0-rc4+staging"
}
```

---

## 참고 자료

### Whisky Wine 구현 참고

- `WhiskyKit/Sources/WhiskyKit/Wine/Wine.swift`
- WINEPREFIX, WINEDEBUG 환경 변수 설정
- Process 실행 및 AsyncStream 패턴
- DXVK 통합 로직

### Gcenx Wine Builds

- GitHub: https://github.com/Gcenx/macOS_Wine_builds
- 릴리즈: wine-staging-11.0-rc4-osx64.tar.xz

### GPTK (Game Porting Toolkit)

- D3DMetal.framework: DirectX → Metal 변환
- 설치 경로: `/Applications/Game Porting Toolkit.app/Contents/Resources/wine/lib/external/`

---

## 라이선스

PodoSoju는 Gcenx Wine-Staging의 재패키징으로, Wine의 LGPL 라이선스를 따릅니다.

- Wine: LGPL 2.1+
- D3DMetal: Apple GPTK 라이선스

---

**작성일:** 2026-01-07
**작성자:** Do
**버전:** 1.0
