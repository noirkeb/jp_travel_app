/// OCR로 인식된 한 줄(또는 한 항목)의 원문과 번역 결과를 담는 모델.
/// 1단계에서는 "줄 단위" 인식으로 시작하고,
/// 이후 요리명/가격을 분리하는 파싱 로직을 이 모델 위에 얹을 예정.
class MenuItem {
  final String originalText; // OCR로 인식된 일본어 원문
  final String translatedText; // 번역된 한국어 텍스트
  final bool isLikelyPrice; // "¥", 숫자 위주 줄이면 가격으로 추정

  MenuItem({
    required this.originalText,
    required this.translatedText,
    this.isLikelyPrice = false,
  });

  factory MenuItem.fromTexts({
    required String original,
    required String translated,
  }) {
    final priceRegex = RegExp(r'^[¥￥]?\s*[\d,]+\s*円?$');
    return MenuItem(
      originalText: original,
      translatedText: translated,
      isLikelyPrice: priceRegex.hasMatch(original.trim()),
    );
  }
}
