# AI 뷰티 상담사 (AI Beauty Counselor)

AI 기술을 활용한 개인 맞춤형 뷰티 상담 서비스입니다.

## 기술 스택

- **Ruby on Rails 8.0** - 백엔드 프레임워크
- **Hotwire (Turbo + Stimulus)** - 프론트엔드 상호작용
- **Tailwind CSS** - 스타일링
- **SQLite** - 데이터베이스

## 주요 기능

- 🎯 개인 맞춤형 피부 분석
- 💄 AI 기반 뷰티 제품 추천
- 📱 반응형 웹 디자인
- ⚡ Hotwire를 활용한 빠른 상호작용
- 🎨 Tailwind CSS로 구현된 현대적인 UI

## 설치 및 실행

### 필요 조건

- Ruby 3.3.0 이상
- Rails 8.0 이상
- SQLite3

### 설치

```bash
# 저장소 클론
git clone [repository-url]
cd ai-beauty-counselor

# 의존성 설치
bundle install

# 데이터베이스 설정
rails db:create db:migrate

# Tailwind CSS 빌드
rails tailwindcss:build
```

### 실행

```bash
# 개발 서버 실행 (Rails + Tailwind CSS watch)
bin/dev

# 또는 Rails 서버만 실행
rails server
```

브라우저에서 `http://localhost:3000`으로 접속하세요.

## 프로젝트 구조

```
app/
├── controllers/
│   └── pages_controller.rb          # 랜딩페이지 컨트롤러
├── views/
│   └── pages/
│       └── home.html.erb            # 메인 랜딩페이지
├── javascript/
│   └── controllers/
│       ├── modal_controller.js      # 모달 제어
│       └── consultation_controller.js # 상담 폼 제어
└── assets/
    └── stylesheets/
        └── application.css          # 기본 스타일
```

## 사용법

1. **메인 페이지 접속**: 브라우저에서 애플리케이션에 접속
2. **상담 시작**: "무료 상담 시작하기" 버튼 클릭
3. **정보 입력**: 피부타입, 고민사항, 예산 범위 입력
4. **AI 분석**: 입력된 정보를 바탕으로 AI가 분석 수행
5. **결과 확인**: 맞춤형 제품 추천 및 뷰티 루틴 제안

## 개발 정보

### Hotwire 활용

- **Turbo**: 페이지 간 빠른 네비게이션
- **Stimulus**: 모달, 폼 제출 등 JavaScript 상호작용

### Tailwind CSS

- 유틸리티 우선 CSS 프레임워크
- 반응형 디자인 구현
- 그라데이션 및 현대적인 UI 컴포넌트

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
