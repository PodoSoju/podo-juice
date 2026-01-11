# Soju Wine 11.0-rc4 통합 요약

## 완료 사항 ✅

### 1. PodoSoju 패키징 (podo-soju)

**패키지:**
- `PodoSoju-11.0-rc4.tar.gz` (336MB)
- Wine 11.0-rc4 (Staging) + D3DMetal
- 버전: 11.0.0-rc4+staging

**경로:**
```
~/Work/podo-soju/dist/PodoSoju-11.0-rc4.tar.gz
```

**설치:**
```bash
tar -xzf PodoSoju-11.0-rc4.tar.gz -C ~/Library/Application\ Support/com.soju.app/
```

**결과:**
```
~/Library/Application Support/com.soju.app/
├── Libraries/
│   ├── PodoSoju/
│   │   ├── bin/wine         # Mach-O x86_64
│   │   ├── bin/wineserver
│   │   ├── bin/wineboot
│   │   └── lib/             # D3DMetal.framework 포함
│   └── PodoSojuVersion.plist
```

### 2. SojuKit - PodoSojuManager 구현

**파일:**
- `SojuKit/Sources/SojuKit/Managers/PodoSojuManager.swift`

**주요 기능:**
```swift
// Singleton
PodoSojuManager.shared

// Wine 환경 변수 생성
.constructEnvironment(for: workspace) -> [String: String]

// Wine 프로세스 실행
.runWine(args: [String], workspace: Workspace) -> AsyncStream<ProcessOutput>

// wineboot 실행 (prefix 초기화)
.runWineboot(workspace: Workspace) async throws

// Workspace 초기화
.initializeWorkspace(_ workspace: Workspace) async throws
```

**환경 변수 자동 설정:**
- `WINEPREFIX`: Workspace 경로
- `WINEDEBUG=fixme-all`: 디버그 메시지 최소화
- `GST_DEBUG=1`: GStreamer 로그 최소화
- Workspace 커스텀 환경변수

### 3. Workspace 통합

**파일:**
- `SojuKit/Sources/SojuKit/Models/Workspace.swift`

**추가된 메서드:**
```swift
// Wine 환경 변수
public func wineEnvironment() -> [String: String]

// Wine prefix 초기화
public func initializeWinePrefix() async throws
```

**Program 실행:**
```swift
// Program.run(in: workspace) 내부에서 PodoSojuManager 사용
let podoSoju = PodoSojuManager.shared
for await output in try podoSoju.runWine(args: ["start", "/unix", url.path], workspace: workspace) {
    // 처리
}
```

### 4. 빌드 성공

**SojuKit:**
```bash
$ cd /Users/max/Work/Soju/SojuKit && swift build
Build complete! (1.55s)
```

**Soju 앱:**
```bash
$ cd /Users/max/Work/Soju && xcodebuild -scheme Soju -configuration Debug build
** BUILD SUCCEEDED **
```

### 5. 테스트 완료

**테스트 스크립트:**
```bash
$ ./Scripts/test-podosoju.swift
✅ PodoSoju 설치 확인
✅ 실행 권한 확인
✅ PodoSoju 버전: 11.0.0-rc4+staging
✅ Wine 버전: wine-11.0-rc4 (Staging)
✅ 모든 테스트 성공
```

---

## 사용 방법

### 기본 사용

```swift
import SojuKit

// 1. Workspace 생성
let workspace = Workspace(workspaceUrl: URL(fileURLWithPath: "~/Documents/MyWorkspace"))

// 2. Wine prefix 초기화
try await workspace.initializeWinePrefix()

// 3. 프로그램 실행
let program = Program(
    name: "notepad",
    url: workspace.winePrefixURL.appending(path: "windows/system32/notepad.exe")
)
try await program.run(in: workspace)
```

### 직접 Wine 명령 실행

```swift
let podoSoju = PodoSojuManager.shared

for await output in try podoSoju.runWine(args: ["--version"], workspace: workspace) {
    switch output {
    case .message(let msg):
        print(msg)
    case .error(let err):
        print("ERROR: \(err)")
    case .terminated(let code):
        print("Exit code: \(code)")
    case .started:
        print("Started")
    }
}
```

---

## 기술 상세

### ProcessOutput 타입

```swift
public enum ProcessOutput {
    case started                // 프로세스 시작
    case message(String)        // stdout
    case error(String)          // stderr
    case terminated(Int32)      // 종료 (exit code)
}
```

### PodoSojuVersion

```swift
public struct PodoSojuVersion: Codable {
    public let major: Int           // 11
    public let minor: Int           // 0
    public let patch: Int           // 0
    public let preRelease: String?  // "rc4"
    public let build: String?       // "staging"
}
```

---

## 커밋 정보

### Soju 커밋

```
commit 1e9605b
feat: Integrate PodoSoju Wine 11.0-rc4

- PodoSojuManager: Wine 바이너리 경로 관리 및 프로세스 실행
- Workspace: PodoSoju 연결 (wineEnvironment, initializeWinePrefix)
- Program: Wine 프로그램 실행 통합 (AsyncStream 기반)
```

**통계:**
- 11 files changed
- 2091 insertions(+)
- 8 deletions(-)

### podo-soju 커밋

```
commit 5a89d0c
refactor: Rename SojuWine to PodoSoju

- package.sh: SojuWine → PodoSoju 일괄 변경
- Output: PodoSoju-11.0-rc4.tar.gz
- Version file: PodoSojuVersion.plist
```

---

## 다음 단계

### 즉시 가능한 작업

1. **wineboot 초기화 테스트**
   ```swift
   let workspace = Workspace(workspaceUrl: testURL)
   try await workspace.initializeWinePrefix()
   // drive_c 구조 확인
   ```

2. **notepad.exe 실행 테스트**
   ```swift
   let program = Program(
       name: "notepad",
       url: workspace.winePrefixURL.appending(path: "windows/system32/notepad.exe")
   )
   try await program.run(in: workspace)
   ```

3. **환경 변수 검증**
   - WINEPREFIX 올바르게 설정되는지 확인
   - Workspace별 환경변수 분리 확인

### 중기 작업

4. **DXVK 통합**
   - DXVK DLL 설치 메서드 구현
   - DirectX → Metal 변환 테스트

5. **UI 통합**
   - Workspace 생성 마법사
   - 프로그램 실행 UI
   - 실행 중인 프로그램 목록

6. **오류 처리**
   - Wine 크래시 복구
   - 명확한 에러 메시지
   - 로그 파일 관리

### 장기 작업

7. **Winetricks 통합**
8. **Windows 버전 설정**
9. **성능 최적화**

---

## 참고 문서

- `PODOSOJU_INTEGRATION.md`: 상세 통합 가이드
- `Scripts/test-podosoju.swift`: 설치 검증 스크립트
- `podo-soju/scripts/package.sh`: 패키징 스크립트

---

**작성일:** 2026-01-07
**PodoSoju 버전:** 11.0.0-rc4+staging
**Wine 버전:** wine-11.0-rc4 (Staging)
