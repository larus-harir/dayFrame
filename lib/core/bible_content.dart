import 'dart:convert';
import 'bible_data.dart';

class BibleContent {
  const BibleContent({
    this.verses = const {},
    this.source = '',
    this.copyright = '',
  });
  final Map<String, String> verses;
  final String source;
  final String copyright;

  factory BibleContent.parse(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['translation'] != '개역개정' ||
        data['verses'] is! Map) {
      throw const FormatException('개역개정 본문 JSON 형식을 확인해주세요.');
    }
    final verses = <String, String>{};
    for (final entry in (data['verses'] as Map).entries) {
      final key = entry.key.toString();
      final location = bibleVerseFromKey(key);
      if (location == null ||
          location.key != key ||
          entry.value is! String ||
          (entry.value as String).trim().isEmpty) {
        throw FormatException('본문의 절 번호나 내용을 확인해주세요: $key');
      }
      verses[key] = (entry.value as String).trim();
    }
    if (verses.isEmpty) throw const FormatException('본문이 비어 있습니다.');
    return BibleContent(
      verses: verses,
      source: data['source']?.toString() ?? '',
      copyright: data['copyright']?.toString() ?? '',
    );
  }
}

Uri officialBibleUri(BibleVerse verse) =>
    Uri.https('www.bskorea.or.kr', '/bible/korbibReadpage.php', {
      'version': 'GAE',
      'book': _bookCodes[verse.book],
      'chap': '${verse.chapter}',
      'sec': '${verse.verse}',
    });

const _bookCodes = [
  'gen',
  'exo',
  'lev',
  'num',
  'deu',
  'jos',
  'jdg',
  'rut',
  '1sa',
  '2sa',
  '1ki',
  '2ki',
  '1ch',
  '2ch',
  'ezr',
  'neh',
  'est',
  'job',
  'psa',
  'pro',
  'ecc',
  'sng',
  'isa',
  'jer',
  'lam',
  'ezk',
  'dan',
  'hos',
  'jol',
  'amo',
  'oba',
  'jon',
  'mic',
  'nam',
  'hab',
  'zep',
  'hag',
  'zec',
  'mal',
  'mat',
  'mrk',
  'luk',
  'jhn',
  'act',
  'rom',
  '1co',
  '2co',
  'gal',
  'eph',
  'php',
  'col',
  '1th',
  '2th',
  '1ti',
  '2ti',
  'tit',
  'phm',
  'heb',
  'jas',
  '1pe',
  '2pe',
  '1jn',
  '2jn',
  '3jn',
  'jud',
  'rev',
];
