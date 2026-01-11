# Plan Auto-Archive Feature

## Overview

세션 종료 시 최근 생성된 플랜 파일을 자동으로 타임스탬프가 포함된 아카이브로 저장합니다.

## How It Works

### 1. Plan File Detection

SessionEnd hook이 실행될 때:
- `.do/plans/` 디렉토리에서 지난 1시간 내 생성/수정된 `.md` 파일을 탐색
- 재귀적으로 모든 하위 디렉토리 검색

### 2. Archive Structure

원본 파일: `.do/plans/2026/01/08.user-auth.md`

아카이브 위치: `.do/plan/2026/01/08/20260108-143022-user-auth.plan`

디렉토리 구조:
```
.do/plan/
  └── {YYYY}/
      └── {MM}/
          └── {DD}/
              └── {YYYYMMDD-HHmmss-title}.plan
```

### 3. Filename Format

- **타임스탬프**: `YYYYMMDD-HHmmss` (예: `20260108-143022`)
- **제목**: 원본 파일명에서 날짜 접두사 제거 (예: `08.user-auth.md` → `user-auth`)
- **확장자**: `.plan`

### 4. Session Summary

세션 종료 시 출력:
```
✅ Session Ended
   📋 Plans archived: 2
```

JSON 결과에 포함:
```json
{
  "plans_archived": {
    "count": 2,
    "paths": [
      ".do/plan/2026/01/08/20260108-143022-user-auth.plan",
      ".do/plan/2026/01/08/20260108-143030-api-design.plan"
    ]
  }
}
```

## Usage

### 1. Create Plan with `/do:plan`

```bash
/do:plan user-authentication
```

플랜 파일이 생성됩니다:
- `.do/plans/2026/01/08.user-authentication.md`

### 2. Automatic Archive on Session End

세션을 종료하면 자동으로:
- `.do/plan/2026/01/08/20260108-143022-user-authentication.plan` 생성
- 원본 파일은 유지됨 (백업 목적)

### 3. View Archived Plans

```bash
ls -la .do/plan/2026/01/08/
```

결과:
```
20260108-120000-user-auth.plan
20260108-143022-user-auth.plan
20260108-150015-api-design.plan
```

## Configuration

### Time Window

기본값: 1시간 (3600초)

코드 위치: `.claude/hooks/do/session_end__auto_cleanup.py`
```python
cutoff_time = time.time() - 3600  # 1 hour ago
```

### Enable/Disable

현재 항상 활성화됨. 비활성화하려면 hook을 수정하거나 조건부 실행을 추가하세요.

## Implementation Details

### Functions Added

#### `find_recent_plan_files() -> List[Path]`

- `.do/plans/` 디렉토리에서 최근 플랜 파일 탐색
- 1시간 내 수정된 `.md` 파일 반환
- 재귀적 검색 (`rglob("*.md")`)

#### `save_plan_to_archive(plan_file: Path) -> Optional[Path]`

- 플랜 파일을 타임스탬프가 포함된 아카이브로 복사
- 디렉토리 구조 자동 생성
- 원본 파일 수정 시간 보존 (`shutil.copy2`)
- 성공 시 아카이브 경로 반환

### Integration Point

`execute_session_end_workflow()` 함수 내 Phase P1-1.5:

```python
# P1-1.5: Archive recent plan files
archived_plans = []
plans_to_archive = find_recent_plan_files()
for plan_file in plans_to_archive:
    archive_path = save_plan_to_archive(plan_file)
    if archive_path:
        archived_plans.append(str(archive_path))
```

## Benefits

### 1. Version History
- 각 세션마다 플랜의 스냅샷 저장
- 플랜 변경 이력 추적 가능

### 2. No Manual Effort
- 자동으로 실행됨
- 별도 명령어 불필요

### 3. Timestamped Backups
- 정확한 생성 시간 기록
- 시간순 정렬 가능

### 4. Safe Workflow
- 원본 파일 유지
- 아카이브는 복사본
- 데이터 손실 없음

## Troubleshooting

### Plans Not Archived

**원인**: 플랜 파일이 1시간 이상 전에 생성됨

**해결**: 파일을 수정하여 modification time 업데이트
```bash
touch .do/plans/2026/01/08.user-auth.md
```

### Archive Directory Not Created

**원인**: 권한 문제 또는 경로 오류

**확인**:
```bash
ls -la .do/
mkdir -p .do/plan/2026/01/08
```

### Duplicate Archives

**예상 동작**: 세션을 여러 번 종료하면 동일한 플랜의 여러 아카이브 생성됨

**정리**:
```bash
# 오래된 아카이브 정리 (30일 이상)
find .do/plan -name "*.plan" -mtime +30 -delete
```

## Future Enhancements

- [ ] 설정 가능한 time window
- [ ] 자동 정리 정책 (오래된 아카이브 삭제)
- [ ] 플랜 diff 기능 (버전 비교)
- [ ] Git 통합 (플랜 변경 시 자동 커밋)
- [ ] 플랜 복원 명령어 (`/do:restore-plan`)

## Related Files

- Hook: `.claude/hooks/do/session_end__auto_cleanup.py`
- Command: `.claude/commands/do/plan.md`
- Archive Dir: `.do/plan/`
- Source Dir: `.do/plans/`

## Version

- **Added**: 2026-01-08
- **Status**: Production
- **Maintainer**: Do Framework
