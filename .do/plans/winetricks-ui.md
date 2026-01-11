# Winetricks UI 개선 계획

## 현재 문제
- 하드코딩된 몇 개 컴포넌트만 표시
- URLSession 다운로드 진행률 제대로 작동 안 함
- Install 버튼 누르면 크래시 (recursive lock 문제)

## Whisky 방식 분석

### 1. Verb 목록 가져오기
```bash
winetricks list-all
```
출력 형식:
```
===== apps =====
7zip                     7-Zip 24.09 (Igor Pavlov, 2024) [downloadable]
===== dlls =====
vcrun2019                Visual C++ 2015-2019 ...
===== fonts =====
corefonts                MS Core Fonts ...
```

### 2. 실행 방식
Whisky는 Terminal.app으로 실행:
```swift
let script = """
tell application "Terminal"
    activate
    do script "\(winetricksCmd)"
end tell
"""
NSAppleScript(source: script)?.executeAndReturnError(&error)
```

## 구현 계획

### Phase 1: Verb 파싱
- `SojuManager.listWinetricksVerbs()` 추가
- `winetricks list-all` 실행 후 파싱
- 카테고리별 verb 목록 반환

### Phase 2: UI 변경
- `WinetricksTab` → `WinetricksView` (별도 시트)
- TabView로 카테고리 표시 (앱, DLLs, 글꼴, 설정)
- Table로 verb 목록 표시 (이름, 설명)
- 검색 기능 추가

### Phase 3: 실행 방식
- Terminal.app으로 실행 (Whisky 방식 채택)
- AppleScript로 터미널 열고 winetricks 명령 실행
- WinetricksDownloader.swift 삭제 (불필요)

### 주요 파일
- `PodoSojuKit/Managers/SojuManager.swift` - verb 파싱 추가
- `PodoSoju/Views/Workspace/WinetricksView.swift` - 새 UI
- `PodoSoju/Services/WinetricksDownloader.swift` - 삭제 또는 단순화

## 검증
1. 앱 실행
2. Workspace Settings → Winetricks 탭
3. 전체 verb 목록 표시 확인
4. verb 선택 후 실행 → Terminal.app 열림 확인
