# Soju 바탕화면 UI 구현 완료

## 생성된 파일

### 1. Models
- **Soju/Models/DesktopIcon.swift**
  - `DesktopIcon` 구조체: 바탕화면 아이콘 데이터 모델
  - `Identifiable`, `Hashable` 프로토콜 준수
  - 속성: id, name, url, position, iconImage

### 2. Views
- **Soju/Views/Desktop/DesktopView.swift**
  - 메인 바탕화면 뷰
  - Windows 스타일 바탕화면 UI
  - Workspace 통합 (SojuKit 사용)
  - 배경 이미지/그라디언트 표시
  - 아이콘 그리드 레이아웃
  - GeometryReader로 반응형 레이아웃

- **Soju/Views/Desktop/DesktopIconView.swift**
  - 개별 아이콘 뷰 컴포넌트
  - 선택 상태 표시
  - Hover 효과
  - 단일/더블 클릭 핸들러
  - Windows 스타일 아이콘 디자인

### 3. ContentView 업데이트
- **Soju/ContentView.swift**
  - WorkspaceManager 통합
  - 워크스페이스 개수에 따른 분기:
    - 0개: 빈 상태 화면
    - 1개: 바로 바탕화면으로
    - 2개+: 워크스페이스 선택 화면
  - WorkspaceCard 컴포넌트 추가

## Xcode 프로젝트에 파일 추가 필요

생성된 파일들을 Xcode 프로젝트에 수동으로 추가해야 합니다:

1. Xcode에서 Soju 프로젝트 열기
2. Project Navigator에서 Soju 그룹 선택
3. 파일 추가:
   - Soju/Models/DesktopIcon.swift
   - Soju/Views/Desktop/DesktopView.swift
   - Soju/Views/Desktop/DesktopIconView.swift
4. Target Membership를 "Soju"로 설정

## 빌드 방법

```bash
cd /Users/max/Work/Soju
xcodebuild -scheme Soju -configuration Debug build
```

## 주요 기능

### DesktopView
- Workspace별 바탕화면 표시
- drive_c 구조 기반 아이콘 자동 로드
- My Computer, Desktop, Documents 폴더 아이콘
- 클릭으로 선택, 더블클릭으로 열기

### DesktopIconView
- SF Symbols 기반 아이콘
- 선택/비선택 상태 표시
- Hover 효과
- 아이콘 이름 라벨 (2줄 제한)

### ContentView
- WorkspaceManager와 통합
- 자동 워크스페이스 선택 (1개일 때)
- 워크스페이스 선택 화면 (2개 이상)
- 빈 상태 처리

## UI 구조

```
ContentView
├─ emptyStateView (워크스페이스 없음)
├─ DesktopView (1개 워크스페이스)
└─ workspaceSelectionView (2개+ 워크스페이스)
   └─ WorkspaceCard (각 워크스페이스)

DesktopView
├─ desktopBackground (배경 이미지/그라디언트)
└─ ForEach(icons)
   └─ DesktopIconView (각 아이콘)
```

## 향후 개선 사항

1. 아이콘 드래그 앤 드롭
2. 아이콘 위치 저장/불러오기
3. 커스텀 배경 이미지 설정
4. 바탕화면 컨텍스트 메뉴
5. 실제 Wine 프로그램 실행 통합
6. 아이콘 자동 정렬
7. 그리드 스냅

## 스타일링

- SF Symbols 아이콘 사용
- Windows 스타일 선택 효과
- 반투명 배경
- 그림자 효과로 가독성 향상
- macOS 14.0+ API 사용
