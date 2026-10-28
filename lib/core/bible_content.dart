import 'dart:convert';
import 'package:csv/csv.dart';
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
    final input = raw.replaceFirst(RegExp(r'^\uFEFF'), '').trimLeft();
    final data = input.startsWith('{') || input.startsWith('[')
        ? jsonDecode(input)
        : _readCsv(input);
    if (data is! Map ||
        data['translation'] != '개역개정' ||
        data['verses'] is! Map) {
      throw const FormatException('개역개정 본문 형식과 번역명을 확인해주세요.');
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
  String toJson() => jsonEncode({
    'translation': '개역개정',
    'source': source,
    'copyright': copyright,
    'verses': verses,
  });

  String toCsv() {
    final rows = <List<String>>[
      [
        'book',
        'chapter',
        'verse',
        'text',
        'translation',
        'source',
        'copyright',
      ],
    ];
    for (var i = 0; i < totalBibleVerses; i++) {
      final verse = bibleVerseAt(i);
      final text = verses[verse.key];
      if (text == null) continue;
      rows.add([
        bibleBookNames[verse.book],
        '${verse.chapter}',
        '${verse.verse}',
        text,
        rows.length == 1 ? '개역개정' : '',
        rows.length == 1 ? source : '',
        rows.length == 1 ? copyright : '',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }
}

Map<String, Object> _readCsv(String input) {
  final firstNewline = input.indexOf('\n');
  final eol = firstNewline > 0 && input[firstNewline - 1] == '\r'
      ? '\r\n'
      : '\n';
  List<List<dynamic>> rows;
  try {
    rows = CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: false,
      eol: eol,
    ).convert(input);
  } catch (_) {
    throw const FormatException('CSV의 따옴표나 줄 구분을 확인해주세요.');
  }
  if (rows.isEmpty) throw const FormatException('본문 CSV가 비어 있습니다.');
  final headers = rows.first.map((v) => v.toString().trim()).toList();
  if (headers.toSet().length != headers.length ||
      ![
        'book',
        'chapter',
        'verse',
        'text',
        'translation',
      ].every(headers.contains)) {
    throw const FormatException(
      'CSV에 book, chapter, verse, text, translation 열이 필요합니다.',
    );
  }
  final metadata = <String, String>{};
  final verses = <String, String>{};
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.every((v) => v.toString().trim().isEmpty)) continue;
    if (row.length != headers.length) {
      throw FormatException('CSV ${i + 1}행의 열 개수를 확인해주세요.');
    }
    String cell(String name) =>
        headers.contains(name) ? row[headers.indexOf(name)].toString() : '';
    for (final name in ['translation', 'source', 'copyright']) {
      final value = cell(name).trim();
      if (value.isEmpty) continue;
      if (metadata.containsKey(name) && metadata[name] != value) {
        throw FormatException('CSV ${i + 1}행의 $name 값이 앞의 행과 다릅니다.');
      }
      metadata[name] = value;
    }
    final bookName = cell('book').trim();
    final book = int.tryParse(bookName) ?? bibleBookNames.indexOf(bookName);
    final chapter = int.tryParse(cell('chapter').trim());
    final verse = int.tryParse(cell('verse').trim());
    final key = '$book:$chapter:$verse';
    if (chapter == null ||
        verse == null ||
        bibleVerseFromKey(key) == null ||
        cell('text').trim().isEmpty) {
      throw FormatException('CSV ${i + 1}행의 권·장·절 또는 본문을 확인해주세요.');
    }
    if (verses.containsKey(key)) {
      throw FormatException('CSV ${i + 1}행에 중복된 절이 있습니다: $key');
    }
    verses[key] = cell('text');
  }
  return {...metadata, 'verses': verses};
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
