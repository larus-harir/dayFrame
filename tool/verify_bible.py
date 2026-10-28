"""내장 본문 구조 검사. --original로 첨부 원본과 변경 내용을 대조한다."""
import argparse
import ast
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BOOKS = '창 출 레 민 신 수 삿 룻 삼상 삼하 왕상 왕하 대상 대하 스 느 에 욥 시 잠 전 아 사 렘 애 겔 단 호 욜 암 옵 욘 미 나 합 습 학 슥 말 마 막 눅 요 행 롬 고전 고후 갈 엡 빌 골 살전 살후 딤전 딤후 딛 몬 히 약 벧전 벧후 요일 요이 요삼 유 계'.split()

def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'중복 키: {key}')
        result[key] = value
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--original', type=Path)
    args = parser.parse_args()
    data = json.loads((ROOT / 'assets/bible/korean_revised.json').read_text(), object_pairs_hook=unique_pairs)
    meta = data['metadata']
    text = (ROOT / 'lib/core/bible/verse_counts.dart').read_text()
    table_start = text.index('[', text.index('const legacyKjvVerseCounts'))
    table_end = text.index('];', table_start)
    counts = ast.literal_eval(text[table_start:table_end + 1])
    counts[46][12] = 13
    counts[63][0] = 15
    expected = {f'{b}:{c + 1}:{v}' for b, chapters in enumerate(counts)
                for c, n in enumerate(chapters) for v in range(1, n + 1)}
    covered = set()
    assert len(counts) == 66 and sum(map(len, counts)) == 1189
    assert meta['translation'] == '개역개정'
    for key, value in data['verses'].items():
        b, c, first = map(int, key.split(':'))
        last = data['ranges'].get(key, first)
        assert value.strip() and not re.search(r'[\x00-\x08\x0b\x0c\x0e-\x1f\ufffd]', value), key
        assert 1 <= first <= last <= counts[b][c - 1], key
        for verse in range(first, last + 1):
            ref = f'{b}:{c}:{verse}'
            assert ref not in covered, ref
            covered.add(ref)
    assert covered <= expected
    assert expected - covered == set(meta['excluded']) == {'43:24:7'}
    assert len(data['verses']) == meta['passages'] == 31088
    assert len(covered) == meta['coveredPositions'] == 31101
    assert len(data['ranges']) == 11
    encoded = json.dumps({'ranges': data['ranges'], 'verses': data['verses']},
                         ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
    assert hashlib.sha256(encoded).hexdigest() == meta['contentSha256']
    if args.original:
        raw = args.original.read_bytes()
        assert hashlib.sha256(raw).hexdigest() == meta['originalSha256']
        original = json.loads(raw.decode('utf-8-sig'), object_pairs_hook=unique_pairs)
        assert len(original) == meta['originalRecords'] == 31089
        original['요18:38'] = original['요18:38'].strip() + ' 이 ' + original.pop('요18:이').strip()
        converted, ranges = {}, {}
        for key, value in original.items():
            match = re.fullmatch(r'([가-힣]+)(\d+):(\d+)(?:-(\d+))?', key)
            assert match, key
            book, chapter, first, last = match.groups()
            canonical = f'{BOOKS.index(book)}:{int(chapter)}:{int(first)}'
            converted[canonical] = value.strip().replace('\x00', '')
            if last:
                ranges[canonical] = int(last)
        assert converted == data['verses'] and ranges == data['ranges']
        print('첨부 원본 대조: 요18:38 병합·바깥 공백·NUL 정리 외 본문 변경 없음')
    print(f'66권 / 1,189장 / {len(covered):,}절 위치 / 합절 11개 검증 통과')
    print('원본 미수록: 사도행전 24:7')

if __name__ == '__main__':
    main()
