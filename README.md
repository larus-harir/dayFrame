# DAYFRAME

성경 읽기, 체크리스트, 일정, 메모를 한 화면에서 보는 Android 플래너.

```sh
flutter pub get
flutter run
```

메인 화면은 성경 → 체크리스트 → 캘린더 → 메모 → 장기 플랜 순서다. 날짜를 누르면 그날 일정이 메모 위에 나온다.
화면에 다 들어가지 않으면 좌우로 넘긴다. 닫기는 항상 하단에 있다. 긴 항목은 페이지 안에서 스크롤할 수 있다.
추가·수정은 오른쪽 위 **관리**에서 한다. 성경은 참조와 읽음 기록만 제공하며 본문은 포함하지 않는다.

**설정 → 표시 권한 허용 → 잠금화면 사용**을 켜면 화면을 켤 때 플래너를 연다.
닫기는 플래너만 닫는다. 휴대폰 잠금은 그대로 유지된다. 재부팅 후에는 앱에서 다시 켜야 한다.
잠금화면의 메모·일정 추가는 **설정 → 잠금화면에서 추가 허용**에서 각각 켠다.
허용하면 잠금을 풀지 않은 사람도 새 항목을 추가할 수 있다. 기존 내용 숨김 설정은 별도로 적용된다.
기기에서 자동 실행을 막으면 알림의 **열기**를 이용한다.

잠금화면에는 `setShowWhenLocked`를 적용한 별도 Activity를 사용한다.
잠금이 풀린 뒤 도착한 자동 실행 요청은 버린다. Android 16·One UI에서의 실제 표시는 기기 확인이 필요하다.

기록은 기기에 저장된다. 저장 키는 `dayframe_data_v1`, 앱 ID는 `com.example.dayframe`이다.
앱 삭제 시 기록도 지워진다. 기존 장 단위 성경 기록은 절 단위로 이전하며 원본을 별도 키에 보관한다.
절 수 출처는 [VERSE_DATA_SOURCE.md](VERSE_DATA_SOURCE.md)에 있다.

검사: `flutter analyze`, `flutter test`. Android 회귀 테스트: `cd android && ./gradlew :app:testDebugUnitTest`.
APK 빌드: `flutter build apk --debug --target-platform android-arm64`.
