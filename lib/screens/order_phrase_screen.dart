import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jp_travel_app/data/order_phrases.dart';

/// 선택한 메뉴로 만든 주문 문장을 보여주는 화면.
/// 상단: 그대로 소리 내어 읽는 한글 발음 / 아래: 점원에게 보여줄 일본어 문장.
class OrderPhraseScreen extends StatelessWidget {
  final OrderPhrase phrase;
  const OrderPhraseScreen({super.key, required this.phrase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            phrase.isSingle ? '주문하기 (단품)' : '주문하기 (${phrase.lines.length}종)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 상단: 한글 발음 (그대로 읽으면 됨) ──
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over,
                          size: 18, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text('이대로 읽어보세요',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    phrase.pronunciation,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (!phrase.pronunciationComplete) ...[
                    const SizedBox(height: 10),
                    Text(
                      '※ 일부 메뉴는 발음 정보가 없어 일본어로 남아있어요. 그 부분은 아래 일본어 문장을 점원에게 보여주세요.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
                    ),
                  ],
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

          // ── 점원에게 보여줄 일본어 문장 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront, size: 18),
                      SizedBox(width: 6),
                      Text('점원에게 보여줘도 돼요 (일본어)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    phrase.japanese,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w600, height: 1.4),
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
          const SizedBox(height: 12),

          // ── 주문 내역 ──
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
        ],
      ),
    );
  }
}
