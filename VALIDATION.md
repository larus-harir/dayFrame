# 검증 기록 — 2026-10-26

## 실제 수행한 검사

- Dart 22개 파일 tree-sitter 구문 파싱: 오류 없음. Dart 타입 분석이나 Flutter 실행 검사를 대신하지 않습니다.
- 고정 Git 커밋의 원본 KJV JSON과 포함한 모든 장별 절 수 비교: 일치.
  66권, 1,189장, 31,102절 합계 확인. 본문은 저장/배포하지 않았습니다.
- Android 준비 스크립트를 기존 AndroidManifest.xml 테스트 픽스처에 3회 적용:
  Activity/Service 중복 없음, Kotlin 3개 파일 복사 확인, 재적용 후 manifest 동일.
  Flutter로 플랫폼을 새로 만드는 분기와 Gradle 빌드는 실행하지 못했습니다.

## 실행하지 못한 필수 검사

Flutter SDK가 없어 공식 Flutter stable 저장소를 내려받았습니다.
Dart SDK 다운로드(`storage.googleapis.com`)는 클라우드 네트워크 프록시에서 HTTP 403으로 차단되었습니다.
환경 설정 초안에 해당 도메인을 추가했지만 초안 저장만으로 현재 런타임에 적용되지는 않았습니다.
따라서 pub get, flutter analyze, flutter test, APK 빌드는 미실행입니다.
Android SDK와 연결된 Android 16 Galaxy 실기기도 없어 실기기 동작은 미검증입니다.
일정 취소 오류의 원본 스택 트레이스가 없으므로 제보와 동일 오류를 재현했다고 주장하지 않습니다.

## 작성한 Flutter 테스트 (미실행)

- test/bible_data_test.dart: 기존 장 매핑 + 31,102절 전체 왕복 매핑, 경계/범위 검사.
- test/editors_test.dart: 네 편집기의 취소 및 종료 애니메이션, 바깥 터치/뒤로 가기,
  날짜/시간 선택 취소 후 저장, 날짜 선택 중 호스트 제거.
- test/store_test.dart: 새 체크리스트 완료/취소, 기존 장 데이터 이전 및 재로딩/원본 백업,
  절 경계 이동/완료/취소/재로딩, 각 섹션 개인정보 숨김.
- test/widget_test.dart: 오늘 화면 및 내비게이션 (메모리 저장소 사용하도록 보완).

## 환경이 준비된 뒤 실행

README의 준비 명령으로 Android 파일을 생성하고 다음을 수행하세요.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

## Galaxy Android 16 수동 점검

1. 일정 등록 → 입력 → 취소, 바깥 터치, 뒤로 가기. 일정이 추가되지 않아야 함.
2. 날짜/시간 선택기를 각각 취소하고 저장. 입력한 제목과 원래 날짜/시간으로 1회 저장되어야 함.
3. 새 체크리스트의 첫 완료 체크/해제, 앱 재시작 후 날짜별 상태 확인.
4. 기존 앱과 동일 applicationId로 데이터 백업 후 업데이트. 장 기록 날짜·메모·커서 보존 확인.
5. 창세기 1장 31절 완료 → 2장 1절, 재실행/다음날 미완료 위치 유지 확인.
6. 잠금 요약 활성화 후 DAYFRAME 빠른 설정 타일 추가. 잠금 상태 탭과 닫기 동작 확인.
   휴대폰 잠금은 계속 유지되어야 함. 제한되는 기기는 제한 사실 기록.
7. 개인정보 숨김 상태에서 일정/메모/체크리스트/목표 제목이 모두 보이지 않는지 확인.
8. 표시 항목 끄기, 잠금 요약 비활성화 후 타일에서 이전 내용이 보이지 않는지 확인.
9. 날짜가 지난 캐시는 내용을 표시하지 않고 앱 갱신을 안내하는지 확인.
10. 작은 화면/큰 글자에서 요약 잘림과 스크롤, 화면 회전/앱 복귀 확인.

## 주요 변경 파일

- lib/widgets/editors.dart: 컨트롤러 수명을 다이얼로그 경로에 귀속, 비동기 선택 뒤 mounted 확인.
- lib/core/models.dart: 수정 가능한 완료 목록, 네이티브 요약 opt-in 및 개인정보 기본 숨김.
- lib/core/bible_data.dart, verse_counts.dart: 장 데이터 유지 + 별도 절 인덱스/참조/개수 데이터.
- lib/core/store.dart: schemaVersion 2, 기존 JSON 백업/이전, 절별 저장, 저장 완료 대기 API.
- lib/screens/bible_screen.dart, today_screen.dart: 절 단위 진행·탐색·기록·이전 장 메모 표시.
- lib/core/lock_summary.dart: 프리뷰/네이티브가 공유하는 범위 제한 및 개인정보 처리.
- lib/core/lock_surface.dart, lib/main.dart: Android 채널 및 시작/복귀/변경 때 요약 동기화.
- lib/screens/preview_screen.dart, settings_screen.dart: 컴팩트 요약과 네이티브 opt-in/실행.
- platform/android/*.kt: 사용자 타일 탭 → 잠금 위 읽기 전용 Activity, 날짜 지난 캐시 숨김.
- tools/prepare_android.py, setup_windows.ps1: 플랫폼 생성/연동 및 검사 명령.
