# Wine 릴리즈 프로세스

## 저장소 관계

```
wine-fork/ (soju-patch 브랜치)
    │
    │  소스 코드 수정 & 푸시
    ▼
soju/
    │
    │  태그 푸시 → GitHub Actions 빌드
    ▼
GitHub Release (Soju-*.tar.gz)
```

## 워크플로우

### 1. Wine 소스 수정 (wine-fork/)

```bash
cd wine-fork
# 코드 수정
git add -A && git commit -m "feat(soju): ..."
git push origin soju-patch
```

- 브랜치: `soju-patch`
- 태그 불필요 (soju에서 최신 커밋 자동 사용)

### 2. Soju 릴리즈 (soju/)

```bash
cd soju
git tag v11.0-rc5-testNN
git push origin v11.0-rc5-testNN
```

- 태그 형식: `v{VERSION}-test{NUMBER}`
- 예: `v11.0-rc5-test36`
- 태그 푸시 시 GitHub Actions 자동 빌드

### 3. 빌드 프로세스 (자동)

GitHub Actions (`release.yml`):
1. wine-fork/soju-patch 최신 커밋 해시 조회
2. 소스 다운로드 & 빌드
3. DXMT, DXVK, Mono, Gecko 통합
4. Soju-*.tar.gz 패키징
5. GitHub Release 생성

### 참고

- ccache 키에 wine 커밋 해시 포함 → 새 커밋 시 캐시 갱신
- VERSION 파일로 Wine 버전 관리 (현재: 11.0-rc5)
