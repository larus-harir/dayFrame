import 'package:flutter/material.dart';
import '../core/bible/reference.dart';
import '../core/store.dart';
import '../widgets/common.dart';

class BibleJournalScreen extends StatefulWidget {
  const BibleJournalScreen({super.key, required this.store});
  final PlannerStore store;
  @override
  State<BibleJournalScreen> createState() => _BibleJournalScreenState();
}

class _BibleJournalScreenState extends State<BibleJournalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 3, vsync: this);
  late final TextEditingController memo;
  late String editingKey;
  int? reviewPage;
  int historyFilter = 0;
  BibleVerse get verse => bibleVerseAt(reviewPage ?? widget.store.biblePage);
  @override
  void initState() {
    super.initState();
    editingKey = verse.key;
    memo = TextEditingController(
      text: widget.store.bibleNotes[editingKey] ?? '',
    );
    widget.store.addListener(refresh);
  }

  void refresh() {
    if (!mounted) return;
    if (verse.key != editingKey) {
      editingKey = verse.key;
      memo.text = widget.store.bibleNotes[editingKey] ?? '';
    }
    setState(() {});
  }

  void review(int? page) {
    FocusScope.of(context).unfocus();
    reviewPage = page == null
        ? null
        : widget.store.bibleContent.availablePage(page);
    refresh();
    tabs.animateTo(0);
  }

  @override
  void dispose() {
    widget.store.removeListener(refresh);
    tabs.dispose();
    memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('말씀과 기록'),
      bottom: TabBar(
        controller: tabs,
        onTap: (_) => FocusScope.of(context).unfocus(),
        tabs: const [
          Tab(text: '오늘의 말씀'),
          Tab(text: '진행도'),
          Tab(text: '기록'),
        ],
      ),
    ),
    body: TabBarView(
      controller: tabs,
      children: [reader(), progress(), history()],
    ),
  );

  Widget reader() {
    final store = widget.store;
    final location = verse;
    final text = store.bibleContent.verses[location.key];
    final read = store.isBibleRead(location);
    final completed = store.isBibleReadToday(location);
    return ListView(
      key: const PageStorageKey('bible-reader'),
      padding: const EdgeInsets.all(16),
      children: [
        if (reviewPage == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(store.hasReadBibleToday ? '오늘 읽기 완료' : '하루 한 절'),
          ),
        if (reviewPage != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('지난 구절 돌아보기'),
            subtitle: const Text('현재 읽던 위치는 그대로 유지됩니다.'),
            trailing: TextButton(
              onPressed: () => review(null),
              child: const Text('오늘의 말씀으로'),
            ),
          ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      store.bibleContent.referenceFor(location),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('bible-bookmark'),
                    tooltip: '북마크',
                    onPressed: () => store.toggleBibleBookmark(location),
                    icon: Icon(
                      store.bibleBookmarks.contains(location.key)
                          ? Icons.bookmark
                          : Icons.bookmark_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (text != null)
                SelectableText(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(height: 1.7),
                )
              else
                const Text('본문을 불러올 수 없습니다.'),
              const SizedBox(height: 12),
              Text(
                '개역개정 · ${read ? '읽음' : '아직 읽지 않음'}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: location.index == 0
                          ? null
                          : () => review(
                              store.bibleContent.adjacentPage(location, -1),
                            ),
                      child: const Text('이전 절'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: location.index == totalBibleVerses - 1
                          ? null
                          : () => review(
                              store.bibleContent.adjacentPage(location, 1),
                            ),
                      child: const Text('다음 절'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('bible-reader-read'),
                onPressed: reviewPage == null
                    ? completed
                          ? null
                          : store.toggleBibleRead
                    : () => store.toggleReviewedBibleRead(location),
                icon: Icon(
                  completed ? Icons.check_circle_outline : Icons.check,
                ),
                label: Text(
                  reviewPage == null
                      ? completed
                            ? '오늘 읽기 완료'
                            : '읽음'
                      : completed
                      ? '읽음 취소'
                      : read
                      ? '오늘 읽음'
                      : '읽음 표시',
                ),
              ),
              if (reviewPage == null && completed)
                TextButton(
                  onPressed: store.toggleBibleRead,
                  child: const Text('읽음 취소'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey('book-${location.book}'),
          initialValue: location.book,
          decoration: inputStyle('성경'),
          isExpanded: true,
          items: [
            for (var b = 0; b < bibleBookNames.length; b++)
              DropdownMenuItem(value: b, child: Text(bibleBookNames[b])),
          ],
          onChanged: (b) {
            if (b != null) review(bibleVerseIndex(b, 1));
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('chapter-${location.book}-${location.chapter}'),
                initialValue: location.chapter,
                decoration: inputStyle('장'),
                items: [
                  for (var c = 1; c <= bibleChapters[location.book]; c++)
                    DropdownMenuItem(value: c, child: Text('$c장')),
                ],
                onChanged: (c) {
                  if (c != null) review(bibleVerseIndex(location.book, c));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('verse-${location.key}'),
                initialValue: location.verse,
                decoration: inputStyle('절'),
                items: [
                  for (
                    var v = 1;
                    v <= bibleVerseCounts[location.book][location.chapter - 1];
                    v++
                  )
                    if (!store.bibleContent.excluded.contains(
                      '${location.book}:${location.chapter}:$v',
                    ))
                      DropdownMenuItem(value: v, child: Text('$v절')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    review(bibleVerseIndex(location.book, location.chapter, v));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: memo,
          minLines: 3,
          maxLines: 7,
          decoration: inputStyle('이 구절에 남기는 기록'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              store.saveBibleNoteAt(location.key, memo.text);
              showMessage(context, '기록을 저장했습니다.');
            },
            child: const Text('기록 저장'),
          ),
        ),
        if (store.legacyBibleNotes['${location.book}:${location.chapter}']
            case final String note)
          Panel(child: Text('이전 장 메모: $note')),
        ExpansionTile(
          key: const PageStorageKey('bible-chapter-full'),
          title: const Text('이 장 전체 읽기'),
          children: [
            for (final passage in store.bibleContent.chapterPassages(
              location.book,
              location.chapter,
            ))
              ListTile(
                dense: true,
                key: ValueKey(
                  'chapter-verse-${passage.first.book}-${passage.first.chapter}-${passage.first.verse}',
                ),
                selected: passage.keys.contains(location.key),
                title: Text('${passage.reference}\n${passage.text}'),
                trailing: store.isBibleRead(passage.first)
                    ? const Icon(Icons.check, size: 16)
                    : null,
                onTap: () => review(passage.first.index),
              ),
          ],
        ),
        ExpansionTile(
          key: const PageStorageKey('bible-source'),
          title: const Text('본문 안내'),
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('개역개정 본문을 오프라인으로 제공합니다. 합절은 묶어서 표시합니다.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget progress() {
    final store = widget.store;
    final byBook = <int, int>{};
    final byChapter = <String, int>{};
    for (final key in store.bibleReadDates.keys) {
      final item = bibleVerseFromKey(key);
      if (item == null ||
          (store.bibleContent.verses.isNotEmpty &&
              !store.bibleContent.verses.containsKey(key))) {
        continue;
      }
      byBook.update(item.book, (v) => v + 1, ifAbsent: () => 1);
      byChapter.update(
        '${item.book}:${item.chapter}',
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.hasReadBibleToday
                    ? '오늘 읽기 완료 · ${store.todayReadCount}절'
                    : '오늘은 아직 읽기 전이에요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '연속 ${store.bibleReadingStreak}일 · 읽은 날 ${store.bibleReadDayCount}일',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${(store.totalReadCount / store.bibleReadingTotal * 100).toStringAsFixed(1)}% · ${store.totalReadCount} / ${store.bibleReadingTotal}절',
        ),
        const SizedBox(height: 12),
        ProgressPill(value: store.totalReadCount / store.bibleReadingTotal),
        const SizedBox(height: 12),
        Text(
          '오늘 ${store.todayReadCount}절 · 북마크 ${store.bibleBookmarks.length}개 · 기록 ${store.bibleNotes.length}개',
        ),
        TextButton(
          onPressed: () {
            review(store.nextUnreadPage);
          },
          child: const Text('이어서 볼 구절'),
        ),
        for (var b = 0; b < bibleBookNames.length; b++)
          ExpansionTile(
            key: ValueKey('progress-book-$b'),
            title: Text(bibleBookNames[b]),
            subtitle: Text(
              '${byBook[b] ?? 0} / ${store.bibleContent.countForBook(b)}절',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var c = 1; c <= bibleChapters[b]; c++)
                      ActionChip(
                        key: ValueKey('progress-$b-$c'),
                        avatar:
                            (byChapter['$b:$c'] ?? 0) ==
                                store.bibleContent.countForChapter(b, c)
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        label: Text(
                          '$c장 · ${byChapter['$b:$c'] ?? 0}/${store.bibleContent.countForChapter(b, c)}',
                        ),
                        onPressed: () => review(bibleVerseIndex(b, c)),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget history() {
    final store = widget.store;
    final records = store.bibleReadHistory;
    final keys =
        (historyFilter == 1 ? store.bibleNotes.keys : store.bibleBookmarks)
            .where(
              (key) =>
                  bibleVerseFromKey(key) != null &&
                  !store.bibleContent.excluded.contains(key),
            )
            .toList()
          ..sort(
            (a, b) => bibleVerseFromKey(
              a,
            )!.index.compareTo(bibleVerseFromKey(b)!.index),
          );
    final length = historyFilter == 0 ? records.length : keys.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(['읽음', '메모', '북마크'][i]),
                  selected: historyFilter == i,
                  onSelected: (_) => setState(() => historyFilter = i),
                ),
            ],
          ),
        ),
        Expanded(
          child: length == 0
              ? const Center(child: Text('아직 기록이 없습니다.'))
              : ListView.builder(
                  itemCount: length,
                  itemBuilder: (context, index) {
                    final record = historyFilter == 0 ? records[index] : null;
                    final key = record?.verse.key ?? keys[index];
                    final item = record?.verse ?? bibleVerseFromKey(key)!;
                    return ListTile(
                      key: ValueKey(
                        record == null
                            ? 'bible-history-$key'
                            : 'bible-history-$key-${record.date}',
                      ),
                      title: Text(store.bibleContent.referenceFor(item)),
                      subtitle: Text(
                        record?.date ??
                            (historyFilter == 1
                                ? store.bibleNotes[key]!
                                : '북마크'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => review(item.index),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
