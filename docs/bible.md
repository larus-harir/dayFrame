# 성경 데이터

- 본문: `assets/bible/korean_revised.json` (개역개정, 오프라인).
- 출처: 사용자 제공 `bible.json`, https://sieon-dev.tistory.com/127
- 키: `책번호:장:절`. 책번호는 창세기 0부터 요한계시록 65까지.
- `verses`는 본문, `ranges`는 합절의 마지막 절, `metadata`는 개수·해시·제외 절.
- 66권·1,189장, 본문 31,088개가 31,101개 절 위치를 포함한다. 합절은 11개다.
- 사도행전 24:7은 원본에 없어 읽기·선택·진행도에서 제외한다.

수정: `요18:이`를 요한복음 18:38의 “이 말을…”로 병합하고, 바깥 공백과 NUL 30개를 제거했다. 그 외 본문은 보존했다. 공식 역본과의 단어별 전수 대조는 하지 않았다.

```sh
python3 tool/verify_bible.py
python3 tool/verify_bible.py --original /path/to/bible.json
```

본문을 수정하면 `metadata.contentSha256`과 관련 개수도 갱신한다.

이전 숫자 위치를 복원하는 절 개수 표는 [KJV JSON](https://raw.githubusercontent.com/thiagobodruk/bible/98a52a5439c1cfe566676e8508795834424a5f3a/json/en_kjv.json)에서 가져왔다. 현재 표는 개역개정에 맞춰 고린도후서 13장을 13절, 요한삼서 1장을 15절로 사용한다.
저장 형식은 v4다. 이전 읽음 날짜는 하루별 기록으로 옮기며 메모·북마크와 기존 백업은 보존한다.
