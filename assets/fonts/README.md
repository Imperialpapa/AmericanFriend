# Fonts

## Pretendard Variable

Modern Sage 리디자인의 기본 폰트.

### 설치 방법

1. https://github.com/orioncactus/pretendard/releases 에서 최신 릴리스 다운로드
2. `pretendard-{version}.zip` 안의 `public/variable/PretendardVariable.ttf` 파일을
   이 폴더(`assets/fonts/`)에 복사
3. `flutter pub get` 후 hot restart

### 폰트 파일이 없을 때

`pubspec.yaml`에 등록된 폰트 파일이 없으면 빌드는 가능하지만 런타임 경고가 뜨고,
`fontFamily: 'Pretendard'`로 지정한 텍스트는 시스템 기본 sans-serif로 fallback됩니다.
앱은 정상 동작하지만 의도된 디자인과 살짝 달라 보일 수 있습니다.

### 라이선스

Pretendard는 SIL Open Font License 1.1로 배포되며 상업적 사용이 가능합니다.
