import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:jp_travel_app/data/menu_filter.dart';
import 'package:jp_travel_app/models/ocr_block.dart';
import 'package:jp_travel_app/screens/order_select_screen.dart';
import 'package:jp_travel_app/services/ocr_service.dart';
import 'package:jp_travel_app/services/translation_service.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const ResultScreen({super.key, required this.imageBytes});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _ocrService = OcrService();
  final _translationService = TranslationService();

  bool _isLoading = true;
  String? _errorMessage;
  OcrResult? _result;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final ocr = await _ocrService.detectLines(widget.imageBytes);
      if (ocr.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '텍스트를 인식하지 못했습니다. 더 선명하게 다시 찍어보세요.';
        });
        return;
      }

      final translated = await _translationService
          .translateLines(ocr.blocks.map((b) => b.text).toList());
      for (var i = 0; i < ocr.blocks.length; i++) {
        ocr.blocks[i].translatedText =
            i < translated.length ? translated[i] : '';
      }

      if (!mounted) return;
      setState(() {
        _result = ocr;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '처리 중 오류가 발생했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('번역 결과')),
      body: _buildBody(),
      // 컴팩트한 "주문하기" 버튼을 하단 중앙에 배치
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _result == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderSelectScreen(items: _orderableItems()),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('주문하기'),
            ),
    );
  }

  /// 주문 후보 메뉴만 추림.
  /// 1) 텍스트 휴리스틱(가격·제목·설명 제외)
  /// 2) 가격이 있는 메뉴판이면, 같은 행에 가격이 있는 줄만 남김(제목·설명 추가 제거)
  List<OcrBlock> _orderableItems() {
    final blocks = _result!.blocks;
    final priceBoxes = [for (final b in blocks) if (_isPrice(b.text)) b.box];
    final hasPriceColumn = priceBoxes.length >= 3;

    return blocks.where((b) {
      if (!MenuFilter.looksOrderable(b.text, b.translatedText)) return false;
      if (!hasPriceColumn) return true; // 가격 없는 메뉴판은 텍스트 필터만
      if (_containsPrice(b.text)) return true; // 항목 안에 가격 포함
      return _hasNearbyPrice(b.box, priceBoxes); // 같은 행에 가격이 있음
    }).toList();
  }

  static final _priceOnlyRe = RegExp(r'^[¥￥]?\s*\d[\d,]*\s*円?$');
  static final _hasPriceRe = RegExp(r'[¥￥円]|\d{2,}');
  bool _isPrice(String t) => _priceOnlyRe.hasMatch(t.trim());
  bool _containsPrice(String t) => _hasPriceRe.hasMatch(t);

  bool _hasNearbyPrice(Rect box, List<Rect> prices) {
    final cy = box.center.dy;
    final tol = box.height * 0.9;
    for (final p in prices) {
      if ((p.center.dy - cy).abs() <= tol) return true;
    }
    return false;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('텍스트 인식 및 번역 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final result = _result!;
    if (result.imageWidth > 0) {
      return _OverlayView(bytes: widget.imageBytes, result: result);
    }
    // 드문 경우: 이미지 크기 정보 없음 → 사진만 표시
    return Center(child: Image.memory(widget.imageBytes));
  }
}

/// 원본 사진 위 같은 위치에 번역을 겹쳐 그리는 뷰. 핀치 줌으로 확대 가능.
class _OverlayView extends StatelessWidget {
  final Uint8List bytes;
  final OcrResult result;
  const _OverlayView({required this.bytes, required this.result});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / result.imageWidth;
        final displayW = constraints.maxWidth;
        final displayH = result.imageHeight * scale;

        return InteractiveViewer(
          constrained: false,
          minScale: 1,
          maxScale: 5,
          child: SizedBox(
            width: displayW,
            height: displayH,
            child: Stack(
              children: [
                Image.memory(
                  bytes,
                  width: displayW,
                  height: displayH,
                  fit: BoxFit.fill,
                ),
                for (final b in result.blocks)
                  if (b.translatedText.trim().isNotEmpty)
                    _label(b, scale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(OcrBlock b, double scale) {
    final w = b.box.width * scale;
    final h = b.box.height * scale;
    final vertical = b.box.height > b.box.width * 1.7;
    // 칸 크기에 비례하되 최소 12px 보장(너무 작아지지 않게)
    final fontSize = ((vertical ? w : h) * 0.72).clamp(12.0, 22.0);

    if (vertical) {
      // 세로쓰기: 위치만 고정하고 내용 크기대로 (세로로 글자 쌓임)
      return Positioned(
        left: b.box.left * scale,
        top: b.box.top * scale,
        child: _OverlayLabel(
            text: b.translatedText, vertical: true, fontSize: fontSize),
      );
    }
    // 가로쓰기: 가로폭만 맞추고 필요 시 줄바꿈(높이는 자동)
    return Positioned(
      left: b.box.left * scale,
      top: b.box.top * scale,
      width: w,
      child: _OverlayLabel(text: b.translatedText, fontSize: fontSize),
    );
  }
}

/// 원본 글자를 덮는 반투명 흰 배경 + 번역 텍스트.
class _OverlayLabel extends StatelessWidget {
  final String text;
  final bool vertical;
  final double fontSize;
  const _OverlayLabel({
    required this.text,
    required this.fontSize,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w700,
      height: 1.05,
      fontSize: fontSize,
    );

    final Widget content;
    if (vertical) {
      final chars =
          text.replaceAll(' ', '').characters.where((c) => c.isNotEmpty);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final c in chars) Text(c, style: style)],
      );
    } else {
      content = Text(text, textAlign: TextAlign.center, style: style);
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(3),
      ),
      child: content,
    );
  }
}
