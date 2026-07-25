import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jp_travel_app/models/ocr_block.dart';
import 'package:jp_travel_app/services/ocr_service.dart';
import 'package:jp_travel_app/services/translation_service.dart';

class ResultScreen extends StatefulWidget {
  final XFile imageFile;
  const ResultScreen({super.key, required this.imageFile});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _ocrService = OcrService();
  final _translationService = TranslationService();

  bool _isLoading = true;
  String? _errorMessage;
  OcrResult? _result;
  Uint8List? _imageBytes;
  bool _showOverlay = true; // true: 사진 위 오버레이, false: 목록

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);

      // 1. OCR: 줄 단위 텍스트 + 위치 좌표
      final ocr = await _ocrService.detectLines(bytes);
      if (ocr.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '텍스트를 인식하지 못했습니다. 더 선명하게 다시 찍어보세요.';
        });
        return;
      }

      // 2. 번역: 모든 줄을 한 번에 배치 번역
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
      appBar: AppBar(
        title: const Text('번역 결과'),
        actions: [
          if (_result != null)
            IconButton(
              tooltip: _showOverlay ? '목록으로 보기' : '사진 위에 보기',
              icon: Icon(_showOverlay ? Icons.list : Icons.photo),
              onPressed: () => setState(() => _showOverlay = !_showOverlay),
            ),
        ],
      ),
      body: _buildBody(),
    );
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
    if (_showOverlay && _imageBytes != null && result.imageWidth > 0) {
      return _OverlayView(bytes: _imageBytes!, result: result);
    }
    return _ListView(bytes: _imageBytes, result: result);
  }
}

/// 원본 사진 위 같은 위치에 번역을 겹쳐 그리는 뷰.
class _OverlayView extends StatelessWidget {
  final Uint8List bytes;
  final OcrResult result;
  const _OverlayView({required this.bytes, required this.result});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 원본 이미지 픽셀 좌표 -> 화면 표시 크기로 비례 변환
        final scale = constraints.maxWidth / result.imageWidth;
        final displayW = constraints.maxWidth;
        final displayH = result.imageHeight * scale;

        return SingleChildScrollView(
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
                    Positioned(
                      left: b.box.left * scale,
                      top: b.box.top * scale,
                      width: b.box.width * scale,
                      height: b.box.height * scale,
                      child: _OverlayLabel(text: b.translatedText),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 원본 글자를 덮는 반투명 흰 배경 + 번역 텍스트 (칸에 맞춰 자동 축소).
class _OverlayLabel extends StatelessWidget {
  final String text;
  const _OverlayLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 목록(카드) 보기 - 오버레이가 겹쳐 보기 어려울 때 대안.
class _ListView extends StatelessWidget {
  final Uint8List? bytes;
  final OcrResult result;
  const _ListView({required this.bytes, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (bytes != null)
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Image.memory(bytes!, fit: BoxFit.cover),
          ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: result.blocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = result.blocks[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.text,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.translatedText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
