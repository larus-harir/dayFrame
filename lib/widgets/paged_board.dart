import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

class PagedBoard extends StatefulWidget {
  const PagedBoard({
    super.key,
    required this.sections,
    required this.onClose,
    this.compactSections = const {},
    this.compactTriggers = const {},
  });
  final Map<String, Widget> sections;
  final Map<String, Widget> compactSections;
  final Map<String, Widget> compactTriggers;
  final VoidCallback onClose;
  @override
  State<PagedBoard> createState() => _PagedBoardState();
}

class _PagedBoardState extends State<PagedBoard> {
  final controller = PageController();
  final heights = <String, double>{};
  int page = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final budget = (bounds.maxHeight - 32).clamp(1.0, double.infinity);
            final pages = <List<Widget>>[[]];
            var used = 0.0;
            for (final entry in widget.sections.entries) {
              final variants = <(Widget, double)>[
                (entry.value, heights[entry.key] ?? budget),
                if (widget.compactSections[entry.key] case final Widget compact)
                  (compact, heights['compact-${entry.key}'] ?? budget),
              ];
              (Widget, double) choose(double available) {
                final eligible =
                    widget.compactTriggers.containsKey(entry.key) &&
                        (heights['trigger-${entry.key}'] ?? double.infinity) >
                            available
                    ? variants.take(1).toList()
                    : variants;
                return eligible.firstWhere(
                  (item) => item.$2 <= available,
                  orElse: () => eligible.last,
                );
              }

              var chosen = choose(budget - used);
              if (pages.last.isNotEmpty && used + chosen.$2 > budget) {
                pages.add([]);
                used = 0;
                chosen = choose(budget);
              }
              final child = chosen.$1;
              final height = chosen.$2;
              pages.last.add(child);
              used += height;
            }
            if (page >= pages.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && controller.hasClients) {
                  controller.jumpToPage(pages.length - 1);
                }
              });
            }
            return Stack(
              children: [
                Offstage(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final entry in {
                          ...widget.sections,
                          for (final item in widget.compactSections.entries)
                            'compact-${item.key}': item.value,
                          for (final item in widget.compactTriggers.entries)
                            'trigger-${item.key}': item.value,
                        }.entries)
                          _Measure(
                            key: ValueKey(entry.key),
                            onSize: (size) {
                              if (mounted &&
                                  heights[entry.key] != size.height) {
                                setState(
                                  () => heights[entry.key] = size.height,
                                );
                              }
                            },
                            child: SizedBox(
                              width: (bounds.maxWidth - 24).clamp(
                                0,
                                double.infinity,
                              ),
                              child: entry.value,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          gestureSettings: const DeviceGestureSettings(
                            touchSlop: 8,
                          ),
                        ),
                        child: PageView(
                          hitTestBehavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          physics: const _BoardPhysics(),
                          controller: controller,
                          key: const Key('board-pages'),
                          onPageChanged: (value) =>
                              setState(() => page = value),
                          children: [
                            for (var i = 0; i < pages.length; i++)
                              SingleChildScrollView(
                                key: ValueKey('board-page-$i'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: pages[i],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: pages.length > 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: '이전 페이지',
                                  padding: EdgeInsets.zero,
                                  onPressed: page <= 0
                                      ? null
                                      : () => controller.previousPage(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                        ),
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    size: 18,
                                  ),
                                ),
                                Text(
                                  '${page.clamp(0, pages.length - 1) + 1} / ${pages.length}',
                                ),
                                IconButton(
                                  tooltip: '다음 페이지',
                                  padding: EdgeInsets.zero,
                                  onPressed: page >= pages.length - 1
                                      ? null
                                      : () => controller.nextPage(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                        ),
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      SizedBox(
        height: 52,
        width: double.infinity,
        child: TextButton.icon(
          key: const Key('board-close'),
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('닫기'),
        ),
      ),
    ],
  );
}

class _Measure extends SingleChildRenderObjectWidget {
  const _Measure({super.key, required this.onSize, required super.child});
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) => _MeasureBox(onSize);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureBox renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _MeasureBox extends RenderProxyBox {
  _MeasureBox(this.onSize);
  ValueChanged<Size> onSize;
  Size? previous;
  @override
  void performLayout() {
    super.performLayout();
    if (previous != size) {
      previous = size;
      final measured = size;
      WidgetsBinding.instance.addPostFrameCallback((_) => onSize(measured));
    }
  }
}

class _BoardPhysics extends PageScrollPhysics {
  const _BoardPhysics({super.parent});
  @override
  _BoardPhysics applyTo(ScrollPhysics? ancestor) =>
      _BoardPhysics(parent: buildParent(ancestor));
  @override
  double get minFlingDistance => 12;
  @override
  double get minFlingVelocity => 100;
  @override
  double get dragStartDistanceMotionThreshold => 3;
}
