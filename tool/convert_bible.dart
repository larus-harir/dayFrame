import 'dart:io';
import 'package:dayframe/core/bible_content.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2 ||
      !(args[1].endsWith('.json') || args[1].endsWith('.csv'))) {
    stderr.writeln('사용법: dart run tool/convert_bible.dart 입력파일 출력파일.json|csv');
    exitCode = 64;
    return;
  }
  final input = File(args[0]);
  final output = File(args[1]);
  if (await output.exists()) {
    stderr.writeln('출력 파일이 이미 있습니다. 다른 경로를 지정해주세요.');
    exitCode = 64;
    return;
  }
  try {
    final content = BibleContent.parse(await input.readAsString());
    await output.writeAsString(
      args[1].endsWith('.csv') ? content.toCsv() : content.toJson(),
    );
    stdout.writeln('${content.verses.length}절 변환 완료: ${output.path}');
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('파일을 읽거나 쓰지 못했습니다: ${error.path}');
    exitCode = 74;
  }
}
