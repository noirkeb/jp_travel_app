# 일본여행 메뉴판 번역 앱 - 1단계 (MVP)

카메라로 일본어 메뉴판을 찍으면 OCR + 번역을 거쳐 결과를 보여주는 기본 파이프라인입니다.

## 구현된 흐름

```
카메라 촬영 (camera_screen.dart)
    ↓
Google Cloud Vision OCR (ocr_service.dart) - languageHints: ["ja"]
    ↓
Papago 번역 API (translation_service.dart) - ja → ko
    ↓
결과 카드 리스트로 표시 (result_screen.dart)
```

## 실행 전 준비

### 1. Flutter 설치 확인
```bash
flutter --version
```
설치가 안 되어 있다면: https://docs.flutter.dev/get-started/install

### 2. API 키 발급
- **Google Cloud Vision API**
  1. https://console.cloud.google.com 에서 프로젝트 생성
  2. "Cloud Vision API" 활성화
  3. API 키 발급 (사용자 인증 정보 → API 키 만들기)
- **Papago (네이버클라우드플랫폼)**
  1. https://www.ncloud.com/product/aiService/papagoNmt 에서 콘솔 가입
  2. Papago Translation 서비스 신청 → Client ID / Secret 발급

### 3. .env 파일 생성
```bash
cp .env.example .env
```
`.env` 파일을 열어서 발급받은 키를 채워넣으세요. (이 파일은 git에 커밋되지 않습니다)

### 4. 패키지 설치
```bash
flutter pub get
```

### 5. 실행
```bash
flutter run
```
실기기 카메라가 없는 환경(에뮬레이터 등)에서는 화면 하단의 갤러리 아이콘으로
저장된 메뉴판 사진을 선택해서 테스트할 수 있습니다.

## 다음 단계 (2단계 이후 예정)

- [ ] 알레르기 필터: 사용자 설정 화면 + 번역 결과에서 위험 키워드 하이라이트
- [ ] 요리명/가격 구조화 파싱 (지금은 줄 단위 인식만 함)
- [ ] 답변 추천 (상황별 시나리오 세트 → LLM 연동)
- [ ] 영수증 스캔 가계부
- [ ] 번역 API 호출 속도 개선 (현재는 줄마다 순차 호출이라 느림 → 병렬화 또는 배치 처리)
- [ ] 에러/재시도 처리 고도화

## 알려진 제약사항 (1단계 기준)

- 손글씨 메뉴는 인식률이 낮을 수 있습니다 (Vision API 기본 정확도에 의존)
- 표기 요레(揺れ) 사전, 방언 매칭 등 아직 미구현
- 번역이 줄 단위라 여러 줄에 걸친 메뉴 설명은 부자연스럽게 잘릴 수 있음
