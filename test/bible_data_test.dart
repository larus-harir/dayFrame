import 'package:flutter_test/flutter_test.dart';
import 'package:dayframe/core/bible_data.dart';

void main() {
  test('개신교 성경 66권 총 1189장', () {
    expect(bibleBookNames.length, 66);
    expect(bibleChapters.length, 66);
    expect(bibleChapters.reduce((a, b) => a + b), 1189);
  });
  test('장 번호의 처음과 끝 매핑', () {
    expect(bibleAt(0).reference, '창세기 1장');
    expect(bibleAt(49).reference, '창세기 50장');
    expect(bibleAt(50).reference, '출애굽기 1장');
    expect(bibleAt(1188).reference, '요한계시록 22장');
    expect(bibleIndex(65, 22), 1188);
  });
}
