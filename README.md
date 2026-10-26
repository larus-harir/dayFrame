# DAYFRAME (MVP 0.1)

휴대폰에서 오늘 일정, 성경 읽기 진행, 반복 체크리스트, 장기 목표, 메모를 관리해보는 Flutter 앱 초기 버전입니다.

## 시작하기 (Windows · VS Code · Android)

1. Flutter SDK, Android SDK가 설치된 PC에서 이 폴더를 VS Code로 엽니다.
2. 프로젝트 루트에서 아래 명령어를 순서대로 실행합니다.

```powershell
flutter create --platforms=android --project-name dayframe .
flutter pub get
flutter devices
flutter run
```

- `flutter create`는 Android/Gradle 등의 기본 플랫폼 파일을 생성합니다. 이 ZIP에는 `lib/`, `pubspec.yaml` 등 직접 작성한 앱 코드가 포함돼 있습니다.
- 기존 앱 프로젝트 `flutter_application_1`에는 덮어쓰지 마세요. 별도 폴더로 압축을 풀어 사용하세요.
- Flutter 3.47.x / Dart 3.9+ 기준으로 작성했고 실제 기기 빌드 검증은 아직 진행하지 못했습니다.

## 현재 동작하는 기능

- 오늘의 일정과 당일 일정의 메모 상단 고정/고정 해제
- 캘린더에서 일정 추가/수정/삭제 (단일 날짜)
- 요일별 체크리스트 생성/수정/삭제, 날짜별 완료 상태 유지
- 장기 목표 생성/수정/삭제, 단계별 진행 체크 및 진행률
- 메모 추가/수정/삭제/상단 고정
- 성경 66권 / 1,189장 위치 이동, 장별 완료 기록, 오늘 읽은 장 수, 장별 메모
- 화면 표시 설정, 다크 모드, 잠금화면 스타일 **프리뷰**
- `shared_preferences`의 로컬 JSON 저장 (데모 용도)

## 아직 없는 기능

- 실제 안드로이드 잠금화면 자동 표시 또는 OS 잠금화면 위젯
- 알림, 일정 반복 등록, Google Calendar 연동, 클라우드 동기화/백업
- 성경 본문(번역본 사용허가 확인 전에는 포함하지 않음)
- 데이터베이스, 암호화, 로그인, 위젯 배치 변경 기능

**중요:** `설정 > 프리뷰 실행`은 앱 내부 미리보기로 실제 시스템 잠금화면이 아닙니다. Android에서 화면을 켤 때마다 앱을 자동으로 띄우는 기능은 제조사/OS에 따라 제한되므로 별도 네이티브 실기기 검증이 필요합니다.

## 주요 소스

- `lib/main.dart`: 앱 시작, 메인 하단탭
- `lib/core/models.dart`: 일정/목표/메모/체크 데이터 모델
- `lib/core/store.dart`: 데이터 수정과 로컬 저장
- `lib/core/bible_data.dart`: 성경 66권의 장 수 정보
- `lib/screens/`: 개별 화면
- `lib/widgets/editors.dart`: 추가/수정 팝업

## 저장 안내

초기 실행 시 예시 데이터가 자동으로 추가됩니다. 이후에는 직접 수정하거나 삭제할 수 있습니다. 앱 데이터 삭제 및 제거 시 내용이 사라질 수 있으므로 중요한 실사용 정보는 아직 저장하지 않는 것을 권장합니다.
