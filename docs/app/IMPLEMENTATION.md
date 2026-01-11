# Soju 프로그램 실행 로직 구현 완료

## 구현된 파일

### 1. SojuKit/Sources/SojuKit/Models/Workspace.swift
**Program 클래스 구현 (118-200줄)**
- `Program` 클래스: Windows 프로그램 실행 모델
  - `id: UUID` - 고유 식별자
  - `name: String` - 프로그램 이름
  - `url: URL` - .exe 파일 경로
  - `icon: NSImage?` - 아이콘 이미지
  - `@Published isRunning: Bool` - 실행 상태
  - `@Published output: [String]` - 프로세스 출력
  - `@Published exitCode: Int32?` - 종료 코드

**주요 메서드:**
```swift
func run(in workspace: Workspace) async throws
```
- Wine을 통한 비동기 프로그램 실행
- WineManager와 통합
- MainActor를 통한 UI 상태 업데이트
- 출력 스트림 실시간 수집
- 오류 처리 및 로깅

### 2. SojuKit/Sources/SojuKit/Managers/WineManager.swift (신규)
**Wine 실행 매니저**
- Singleton 패턴 (`shared` 인스턴스)
- Whisky의 Wine 설치 위치 사용
- Wine 버전: Whisky가 설치한 wine64 사용

**주요 메서드:**

```swift
func execute(
    program: URL,
    environment: [String: String],
    workingDirectory: URL
) async throws -> AsyncStream<String>
```
- wine64를 통한 프로그램 실행
- `wine start /unix {program}` 명령어 사용
- 표준 출력/오류 스트리밍
- 비동기 프로세스 관리

```swift
func killWineServer(winePrefix: String) async throws
```
- wineserver -k 실행
- 워크스페이스 종료 시 사용

```swift
func wineVersion() async throws -> String
```
- Wine 버전 확인

**오류 타입:**
- `WineManagerError.wineNotFound` - Wine 미설치
- `WineManagerError.programNotFound` - 프로그램 파일 없음
- `WineManagerError.invalidOutput` - 잘못된 출력
- `WineManagerError.executionFailed` - 실행 실패

### 3. Soju/Views/Desktop/DesktopView.swift
**더블클릭 실행 통합 (132-168줄)**

```swift
private func handleIconDoubleTap(_ icon: DesktopIcon)
```
- .exe 파일 감지
- Program 인스턴스 생성
- 워크스페이스에 추가
- 비동기 실행 시작
- 오류 처리 및 정리

**로직 흐름:**
1. 아이콘 더블클릭
2. 파일 확장자 확인 (.exe?)
3. Program 객체 생성
4. workspace.programs 배열에 추가
5. program.run(in: workspace) 비동기 호출
6. 성공/실패 로깅
7. 실패 시 프로그램 배열에서 제거

**ProgramStatusView 통합 (48-57줄)**
- 우측 하단에 실행 중인 프로그램 표시
- 400px 너비 고정
- padding으로 여백 처리

### 4. Soju/Views/Desktop/ProgramStatusView.swift (신규)
**실행 프로그램 상태 UI**

**기능:**
- 실행 중인 프로그램 목록 표시
- 개수 뱃지
- 접기/펼치기 토글
- 각 프로그램별 상태:
  - 실행 중 (녹색 표시)
  - 완료 (파란색 표시)
  - 실패 (빨간색 표시)
- 프로세스 출력 콘솔 (접기/펼치기)
- 모노스페이스 폰트 출력
- 텍스트 선택 가능

**UI 구조:**
```
ProgramStatusView
├─ Header (Running Programs, 개수, 접기/펼치기)
└─ ScrollView
   └─ ProgramRow (각 프로그램)
      ├─ 아이콘, 이름, 상태
      └─ 출력 콘솔 (토글)
```

## 실행 흐름

### 1. 프로그램 실행
```
사용자 더블클릭
    ↓
DesktopView.handleIconDoubleTap()
    ↓
.exe 파일 확인
    ↓
Program 생성
    ↓
workspace.programs.append()
    ↓
program.run(in: workspace)
    ↓
WineManager.shared.execute()
    ↓
wine64 start /unix {program.exe}
    ↓
출력 스트리밍 → program.output
    ↓
종료 → exitCode 설정
```

### 2. 상태 업데이트
```
program.isRunning = true
    ↓
실행 중...
    ↓
출력 수집 (program.output.append)
    ↓
종료 감지
    ↓
program.isRunning = false
program.exitCode = 0 or 1
    ↓
ProgramStatusView 자동 갱신 (@Published)
```

## Wine 통합

### 환경 변수
```swift
workspace.wineEnvironment()
```
- `WINEPREFIX`: 워크스페이스 경로
- `WINEDEBUG`: "fixme-all"
- 추가 커스텀 변수 (WorkspaceSettings)

### 실행 명령어
```bash
{wine64 경로} start /unix {프로그램 경로}
```
- Whisky와 동일한 방식
- /unix 경로로 macOS 파일 시스템 접근

### Wine 설치 경로
```
~/Library/Application Support/
  com.isaacmarovitz.Whisky/
    Libraries/
      Wine/
        bin/
          wine64
          wineserver
```

## 기술 스택

### Swift Concurrency
- `async/await` - 비동기 프로그램 실행
- `AsyncStream` - 프로세스 출력 스트리밍
- `Task` - 백그라운드 실행
- `@MainActor` - UI 스레드 업데이트

### SwiftUI
- `@ObservedObject` - Workspace 관찰
- `@Published` - 자동 UI 갱신
- `GeometryReader` - 반응형 레이아웃
- `.onAppear` - 생명주기 처리

### Foundation
- `Process` - 프로세스 실행
- `Pipe` - 입출력 스트림
- `FileHandle` - 파일 핸들러
- `Logger` - 구조화된 로깅

## 테스트 시나리오

### 1. 간단한 실행 파일 테스트
```bash
# notepad.exe 같은 간단한 프로그램 복사
cp /path/to/notepad.exe ~/path/to/workspace/drive_c/
```

1. Soju 실행
2. 워크스페이스 선택
3. notepad 아이콘 더블클릭
4. ProgramStatusView에서 상태 확인
5. 출력 콘솔 열기
6. 프로그램 종료 대기
7. exitCode 확인

### 2. 오류 처리 테스트
- 존재하지 않는 .exe 파일
- Wine 미설치 상태
- 권한 없는 파일
- 잘못된 실행 파일

### 3. 다중 프로그램 실행
- 여러 프로그램 동시 실행
- workspace.programs 배열 확인
- 각 프로그램 독립적 상태 추적

## 향후 개선 사항

### 1. 프로세스 관리
- [ ] 실행 중인 프로그램 강제 종료
- [ ] 프로세스 일시 중지/재개
- [ ] 자원 사용량 모니터링 (CPU, 메모리)

### 2. 로그 관리
- [ ] 출력 로그 파일 저장
- [ ] 로그 필터링 (오류만, 경고만)
- [ ] 로그 검색 기능

### 3. UI 개선
- [ ] 프로그램 창 에뮬레이션
- [ ] 작업 표시줄 통합
- [ ] 프로그램 아이콘 자동 추출
- [ ] 진행률 표시

### 4. 고급 기능
- [ ] 프로그램 인자 전달
- [ ] 환경변수 커스터마이징
- [ ] 시작 프로그램 설정
- [ ] 프로그램 바로가기 관리

### 5. 오류 복구
- [ ] Wine 크래시 감지 및 재시작
- [ ] 자동 오류 보고
- [ ] 디버그 모드

## 파일 구조

```
Soju/
├─ Soju/
│  └─ Views/
│     └─ Desktop/
│        ├─ DesktopView.swift (수정)
│        └─ ProgramStatusView.swift (신규)
└─ SojuKit/
   └─ Sources/
      └─ SojuKit/
         ├─ Models/
         │  └─ Workspace.swift (수정: Program 클래스)
         └─ Managers/
            └─ WineManager.swift (신규)
```

## 주요 변경 통계

```
Soju/Views/Desktop/DesktopView.swift:          +114 줄
SojuKit/Sources/SojuKit/Models/Workspace.swift: +81 줄
SojuKit/Sources/SojuKit/Managers/WineManager.swift: +232 줄 (신규)
Soju/Views/Desktop/ProgramStatusView.swift:    +188 줄 (신규)
```

## 의존성

- macOS 14.0+
- Whisky Wine 설치 필요
- SojuKit 프레임워크

---

**구현 완료:** 2026-01-07
**버전:** 1.0.0
**상태:** 테스트 준비 완료
