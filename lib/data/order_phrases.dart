import 'package:jp_travel_app/data/japanese_reading.dart';

/// 주문할 메뉴 한 항목 (일본어명 + 한국어명 + 수량).
class OrderLine {
  final String japanese;
  final String korean;
  final int quantity;
  const OrderLine({
    required this.japanese,
    required this.korean,
    required this.quantity,
  });
}

/// 완성된 주문 문장.
class OrderPhrase {
  final String japanese; // 점원에게 보여주거나 말할 일본어 문장
  final String korean; // 뜻
  final String pronunciation; // 한글 발음 (메뉴명 포함, 그대로 읽으면 됨)
  final bool pronunciationComplete; // 발음을 전부 아는지 (일본어 잔여 없음)
  final List<OrderLine> lines;
  const OrderPhrase({
    required this.japanese,
    required this.korean,
    required this.pronunciation,
    required this.pronunciationComplete,
    required this.lines,
  });

  /// 한 종류를 한 개만 주문하는지 (단품 여부).
  bool get isSingle => lines.length == 1 && lines.first.quantity == 1;
}

/// 선택한 메뉴들로 자연스러운 일본어 주문 문장을 만든다. (하드코딩, LLM 미사용)
class OrderComposer {
  // 1~10을 세는 말(つ 계열) — 음식 주문에 두루 통용됨
  static const List<String> _jaCount = [
    '', 'ひとつ', 'ふたつ', 'みっつ', 'よっつ', 'いつつ', //
    'むっつ', 'ななつ', 'やっつ', 'ここのつ', 'とお',
  ];
  static const List<String> _jaCountRead = [
    '', '히토츠', '후타츠', '밋츠', '욧츠', '이츠츠', //
    '뭇츠', '나나츠', '얏츠', '코코노츠', '토오',
  ];

  static String jaCounter(int n) => (n >= 1 && n <= 10) ? _jaCount[n] : '$n個';
  static String jaCounterRead(int n) =>
      (n >= 1 && n <= 10) ? _jaCountRead[n] : '$n코';
  static String koCount(int n) => n == 1 ? '하나' : '$n개';

  static OrderPhrase compose(List<OrderLine> lines) {
    // 일본어: すみません、〇〇をひとつ、△△をふたつ ください。
    final jaParts =
        lines.map((l) => '${l.japanese}を${jaCounter(l.quantity)}').join('、');
    final japanese = 'すみません、$jaParts ください。';

    // 뜻: 저기요, 〇〇 하나, △△ 둘 주세요.
    final koParts =
        lines.map((l) => '${l.korean} ${koCount(l.quantity)}').join(', ');
    final korean = '저기요, $koParts 주세요.';

    // 한글 발음: 스미마셍, 카라아게 테이쇼쿠오 히토츠, … 쿠다사이.
    final pronParts = lines
        .map((l) => '${JapaneseReading.toReading(l.japanese)}오 ${jaCounterRead(l.quantity)}')
        .join(', ');
    final pronunciation = '스미마셍, $pronParts 쿠다사이.';

    return OrderPhrase(
      japanese: japanese,
      korean: korean,
      pronunciation: pronunciation,
      pronunciationComplete: !JapaneseReading.hasJapanese(pronunciation),
      lines: lines,
    );
  }
}
