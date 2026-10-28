# 본문 제공처 조사 · 2026-10-28

## 확인한 후보

- [stranger828/bibleAPI](https://github.com/stranger828/bibleAPI): 개역개정으로 설명한 공개 JSON. 키가 필요한 실시간 API가 아니라 전체 파일을 읽는 방식이다. README는 소스 코드 사용과 본문 저작권을 구분하며, 본문의 대한성서공회 권리 확인이 필요하다고 안내한다.
- [boring-km/nkrv_bible_server](https://github.com/boring-km/nkrv_bible_server): 개역개정 서버 코드. README에 라이선스 관련 이슈가 있다고 명시한다.
- [thiagobodruk/bible](https://github.com/thiagobodruk/bible): 한국어 항목은 Korean Revised(`ko_krv`)이며, 개역개정 데이터라고 확인되지 않았다. 저장소의 코드 라이선스로 원문 권리까지 보장하지 않는다.
- [HelloAOLab/bible-api](https://github.com/HelloAOLab/bible-api): 공개 이용을 표방하는 API. 개역개정 제공 여부는 확인하지 못했다.
- [API.Bible 공식 예제](https://github.com/americanbible/api-bible-js-demo): API 키가 필요하다. 개역개정 접근 가능 여부와 제공 조건은 확인하지 못했다.

## 파일 검증

`stranger828/bibleAPI`의 `883e8f89b65710dd00a50f675b256cb2709cc90f` 시점 JSON은 31,077행이다.
기존 앱의 절 위치 표와 비교하면 26개 위치가 없고, 표에 없는 요한삼서 1:15가 있다.
번역별 절 구분 차이와 누락을 구분해 매핑해야 하며, 이 파일을 그대로 완전한 본문으로 간주하지 않았다.
현재 앱의 절 위치 표는 KJV 계열이므로 개역개정 전체 적용 전 절 번호 검증·기록 이전이 필요하다.

공식 성서공회·일반 검색·API 서비스 도메인은 환경의 네트워크 허용 목록 밖이라 접근이 차단됐다.
GitHub에서 확인 가능한 문서와 데이터 구조를 조사했으며, 공식 이용 허가나 실제 API 운영 상태를 확인한 것은 아니다.
본문 원문은 저장소에 복사하지 않았다. CSV로 변환해도 번역본 권리나 내용 누락은 해결되지 않는다.

CSV 불러오기와 JSON↔CSV 변환 도구는 구현했다. 형식과 사용법은 [BIBLE_CONTENT.md](BIBLE_CONTENT.md)에 있다.
