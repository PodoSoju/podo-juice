# Compact at 2026-01-10 18:44:07

## 대화 요약

### 완료된 작업

**Soju (Wine 빌드) 워크플로우:**
1. PodoSoju/wine 포크 생성 및 패치 적용
   - `cocoa_window.m`: SOJU_EXE_PATH로 window identifier 설정
   - `cocoa_app.m`: SOJU_EXE_PATH로 메뉴바 앱 이름 설정
   - Fallback: UUID 기반 고유 identifier

2. 런타임 라이브러리 번들링 (Gcenx 동일)
   - 38개 라이브러리 (ICU, gnutls, FreeType, MoltenVK 등)
   - FAudio + SDL3 추가 (게임 오디오)
   - Wine Mono, Gecko, Winetricks 포함

3. 빌드 워크플로우 수정
   - 32비트 + 64비트 지원 (`--enable-archs=i386,x86_64`)
   - 라이브러리 복사 시 fallback + cp -f
   - 중복 MoltenVK 복사 문제 해결

**PodoSoju 앱:**
1. MSI 파일 지원 추가
   - Info.plist에 UTType 선언
   - msiexec /i로 실행
   - 파일 선택 다이얼로그에 .msi 추가

2. Run Installer 후 모달 즉시 닫기

### 현재 상태
- 브랜치 (soju): main
- 브랜치 (wine-fork): soju-window-identifier
- test16 빌드 진행 중 (Wine 컴파일 단계)

### 진행 중인 작업
- Window identifier에서 확장자 제거 필요 (`Notepad.exe` → `Notepad`)
- test16 완료 대기 또는 test17 시작

### 다음 할 일
1. cocoa_window.m에서 `stringByDeletingPathExtension` 추가
2. test17 시작 (최신 Wine 포크 포함)
3. 빌드 완료 후 테스트

### 중요 결정사항
- Window identifier: 파일명만 사용 (경로 제외, 확장자 제거)
- Fallback identifier: `wine-{UUID}` (고유성 보장)
- 메뉴바 제목: 앱 이름 또는 "Wine" fallback
- 라이브러리: Gcenx와 100% 동일 + FAudio/SDL3

### 빌드 히스토리
- test10~test15: 다양한 문제로 실패/취소
- test16: 진행 중 (fallback 수정, 라이브러리 38개)
- 예상 완료: ~45분

### Git 커밋 (wine-fork)
```
c0b841f winemac: Use UUID for fallback identifier
d15f7e8 winemac: Use filename only for window identifier
e1cead2 winemac: Use SOJU_EXE_PATH for app menu title
99475c4 winemac: Use hwnd as fallback identifier (삭제됨)
05f73c1 winemac: Add SOJU_EXE_PATH window identifier
```

---
