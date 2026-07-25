import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jp_travel_app/data/order_phrases.dart';

/// 선택한 메뉴로 만든 일본어 주문 문장을 보여주는 화면.
/// 점원에게 화면을 보여주거나, 발음을 참고해 직접 말할 수 있게 안내.
class OrderPhraseScreen extends StatelessWidget {
  final OrderPhrase phrase;
  const OrderPhraseScreen({super.key, required this.phrase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qtys = phrase.lines.map((l) => l.quantity).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(phrase.isSingle ? '주문하기 (단품)' : '주문하기 (${phrase.lines.length}종)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 점원에게 보여줄 일본어 문장
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront, size: 18, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text('점원에게 이 문장을 보여주세요',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    phrase.japanese,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phrase.japanese));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('주문 문장을 복사했어요')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('복사'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('뜻 · ${phrase.korean}',
                style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 20),

          // 주문 내역
          const Text('주문 내역', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final l in phrase.lines)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l.korean),
              subtitle: Text(l.japanese,
                  style: const TextStyle(color: Colors.grey)),
              trailing: Text('${l.quantity}개',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          const Divider(height: 28),

          // 발음 도우미 (고정 표현 + 사용된 수량만)
          const Text('직접 말해보려면 (발음)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _pron('すみません', '스미마셍', '저기요 (점원 부를 때)'),
          for (final q in qtys)
            _pron(OrderComposer.jaCounter(q), OrderComposer.jaCounterRead(q),
                OrderComposer.koCount(q)),
          _pron('ください', '쿠다사이', '주세요'),
          const SizedBox(height: 12),
          Text(
            '팁 · 메뉴 이름은 발음이 어려우니, 위 일본어 문장을 점원에게 보여주는 게 가장 확실해요.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _pron(String ja, String read, String meaning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ja,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('$read  —  $meaning',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }
}
