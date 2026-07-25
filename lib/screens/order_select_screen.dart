import 'package:flutter/material.dart';
import 'package:jp_travel_app/data/order_phrases.dart';
import 'package:jp_travel_app/models/ocr_block.dart';
import 'package:jp_travel_app/screens/order_phrase_screen.dart';

/// 번역된 메뉴 목록에서 주문할 항목을 고르는 화면.
/// 항목을 탭하면 담기고(같은 항목 여러 번 탭 → 수량 증가), +/-로 조절.
class OrderSelectScreen extends StatefulWidget {
  final List<OcrBlock> items;
  const OrderSelectScreen({super.key, required this.items});

  @override
  State<OrderSelectScreen> createState() => _OrderSelectScreenState();
}

class _OrderSelectScreenState extends State<OrderSelectScreen> {
  final Map<int, int> _qty = {}; // 항목 index -> 수량

  int get _selectedCount => _qty.values.where((v) => v > 0).length;

  void _inc(int i) => setState(() => _qty[i] = (_qty[i] ?? 0) + 1);

  void _dec(int i) => setState(() {
        final v = (_qty[i] ?? 0) - 1;
        if (v <= 0) {
          _qty.remove(i);
        } else {
          _qty[i] = v;
        }
      });

  void _goToPhrase() {
    final lines = <OrderLine>[];
    for (var i = 0; i < widget.items.length; i++) {
      final q = _qty[i] ?? 0;
      if (q > 0) {
        lines.add(OrderLine(
          japanese: widget.items[i].text,
          korean: widget.items[i].translatedText,
          quantity: q,
        ));
      }
    }
    if (lines.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPhraseScreen(phrase: OrderComposer.compose(lines)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주문할 메뉴 선택')),
      body: widget.items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('주문할 수 있는 메뉴를 찾지 못했어요.\n메뉴판을 더 선명하게 찍어보세요.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                final q = _qty[i] ?? 0;
                return ListTile(
                  selected: q > 0,
                  onTap: () => _inc(i), // 탭할 때마다 +1
                  title: Text(item.translatedText,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.text,
                      style: const TextStyle(color: Colors.grey)),
                  trailing: q == 0
                      ? const Icon(Icons.add_circle_outline, color: Colors.grey)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _dec(i),
                            ),
                            Text('$q',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () => _inc(i),
                            ),
                          ],
                        ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _selectedCount > 0 ? _goToPhrase : null,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(_selectedCount > 0
                  ? '주문 문장 만들기 ($_selectedCount종 선택)'
                  : '메뉴를 선택하세요'),
            ),
          ),
        ),
      ),
    );
  }
}
