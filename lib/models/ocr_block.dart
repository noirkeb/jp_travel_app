import 'dart:ui' show Rect;

/// OCR로 인식된 한 줄(라인)의 원문·번역과, 원본 이미지 상의 위치(픽셀 좌표).
/// 번역 결과를 원본 사진 위 같은 자리에 겹쳐 그리기 위해 box를 사용한다.
class OcrBlock {
  final String text; // 원문(일본어)
  String translatedText; // 번역(한국어) - 번역 후 채움
  final Rect box; // 원본 이미지 픽셀 좌표계 기준 위치

  OcrBlock({required this.text, this.translatedText = '', required this.box});
}

/// OCR 전체 결과: 원본 이미지 크기 + 인식된 라인 목록.
/// imageWidth/Height로 화면 크기에 맞춰 box 좌표를 비례 변환한다.
class OcrResult {
  final int imageWidth;
  final int imageHeight;
  final List<OcrBlock> blocks;

  OcrResult({
    required this.imageWidth,
    required this.imageHeight,
    required this.blocks,
  });

  bool get isEmpty => blocks.isEmpty;
}
