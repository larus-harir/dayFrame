# DAYFRAME 0.3

Android 개인 플래너입니다. 오늘 화면과 **실제 잠금 위 오버레이 화면**에서 체크리스트·성경 읽기를 조작할 수 있습니다.

## VS Code에서 실행

Flutter stable(Dart 3.9 이상), Android SDK/JDK 17, USB 디버깅이 켜진 휴대폰을 준비하세요.

```sh
git pull origin main
flutter pub get
flutter analyze
flutter test
flutter run
```

네이티브 코드가 변경되었으므로 실행 중인 앱은 종료하고 다시 `flutter run`하세요. Hot Reload만으로는 적용되지 않습니다.
기존 Android 앱 ID `com.example.dayframe`과 저장 키 `dayframe_data_v1`을 유지합니다.
`flutter create .`로 덮어쓸 필요가 없습니다.

## 실제 잠금 위 플래너 켜기

1. 앱 설정 → **실제 잠금 위 플래너** → **다른 앱 위에 표시 허용**.
2. Android 설정에서 DAYFRAME의 표시 권한을 허용하고 앱으로 돌아옵니다.
3. **잠금 플래너 시작**을 누릅니다. 알림 권한도 허용하면 실행 상태와 중지 버튼을 확인하기 쉽습니다.
4. **지금 실제 화면 열기**로 체크·성경 버튼을 시험합니다.
5. 전원 버튼으로 화면을 끄고 다시 켜서 잠금 위 표시 여부를 확인합니다.

실행 중인 foreground service가 화면 켜짐을 감지해 `TYPE_APPLICATION_OVERLAY` 창에 별도 Flutter 화면을 표시합니다.
백그라운드에서 Activity를 강제로 실행하거나 보안 잠금을 해제하지 않습니다. 닫기는 DAYFRAME 창만 닫습니다.
지문/비밀번호 인증은 Android 잠금화면에서 그대로 수행합니다. 알림 또는 앱 설정에서 서비스를 중지할 수 있습니다.

**Android 16 Galaxy 실기기의 잠금 위 표시는 아직 미검증입니다.** One UI의 보안/절전 정책은 다른 앱 위 표시를
잠금화면에서 제한할 수 있습니다. 권한이 허용되어도 모든 기기에서 캐시워크와 같은 자동 표시를 보장하지는 않습니다.
시스템이 서비스나 창을 차단하면 이 기능으로 우회하지 않습니다. 재부팅·강제 종료 후에는 앱에서 다시 시작해야 합니다.

## 직접 조작

- 오늘 화면: 체크리스트 완료/해제, 성경 좌우 스와이프, 이전/다음 버튼, 읽음 및 이전 절의 읽음 취소.
- 잠금 위 화면: 같은 체크리스트·성경 컨트롤과 날짜별 저장 사용. 화면을 닫고 앱에 복귀할 때 저장을 마친 뒤 다시 읽습니다.
- 성경 읽음 체크는 다음 절로 이동합니다. 여러 절을 연속으로 읽거나 이전 절로 돌아가 취소할 수 있습니다.
- 개인정보 숨김은 기본 활성화입니다. 잠금 위에서 실제 항목을 보고 체크하려면 설정의 **개인 내용 숨기기**를 끄세요.
  앱 내부 오늘 화면의 체크리스트는 숨김 설정과 관계없이 조작할 수 있습니다.
- 큰 시계는 제거했습니다. 작은 화면/큰 글자에서는 스크롤로 모든 항목에 접근할 수 있습니다.
- 성경 본문은 포함하지 않습니다. 책·장·절 참조를 보고 소유한 성경에서 읽는 방식입니다.

## 저장과 이전

일정·메모·체크리스트·성경 기록은 기기에만 저장됩니다. 암호화·클라우드 백업은 아직 없습니다.
기존 장 완료는 해당 장의 모든 절로 원래 날짜를 유지해 이전하고 장 메모도 보존합니다.
이전 전 원본 JSON은 `dayframe_data_v1_pre_verse_backup`에 보관합니다.
절 개수 기준·출처는 [VERSE_DATA_SOURCE.md](VERSE_DATA_SOURCE.md)를 참고하세요.

## 구조 및 검증

- `lib/widgets/verse_card.dart`: 메인/잠금 위 공통 성경 조작.
- `lib/lock_overlay.dart`: 서비스에서 별도 Flutter engine으로 실행되는 실제 잠금 위 화면.
- `android/.../LockOverlayService.kt`: 권한 기반 창, 실행 알림, 화면 켜짐/해제 감지.
- `lib/widgets/overlay_settings_card.dart`: 권한·실행 상태·시작·중지 UI.
- `lib/core/store.dart`: 공통 로컬 저장소와 기존 기록 이전.
- `platform/android/`: 네이티브 원본 복사본. 플랫폼 재생성이 필요할 때만 Python 3으로 `tools/prepare_android.py` 실행.

앱 내부 프리뷰와 수동 빠른 설정 요약 타일은 보조 기능으로 남아 있습니다.
검사 결과와 실기기 확인 항목은 [VALIDATION.md](VALIDATION.md)를 확인하세요.
