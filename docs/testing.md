# 검사

Flutter 3.47.8 / Dart 3.13.7 / JDK 21.

```sh
flutter analyze
flutter test
python3 tool/verify_bible.py
cd android
./gradlew :app:testDebugUnitTest :app:assembleDebug
```

읽음·취소, 화면 재열기, 자정 전환, 자동 접기·펼치기, 지난 기록, 저장 형식 이전,
달력·메모 배치와 편집, 표시 여부·순서 통합, 작은 화면·큰 글자·다크 모드, Android 시스템 바 설정을 검사한다.
잠금 자동 표시와 Galaxy 시스템 바·키보드는 실기기 확인이 필요하다.

2026-10-28: Flutter 테스트 65개·Android 테스트 8개, 분석·본문 검증·디버그 빌드 통과.
