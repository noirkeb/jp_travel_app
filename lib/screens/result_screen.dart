import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jp_travel_app/models/menu_item.dart';
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
  List<MenuItem> _items = [];
  Uint8List? _imageBytes; // 미리보기 표시용 (웹/모바일 공통)

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // 0. 이미지 바이트 로드 (File 대신 바이트를 써서 웹에서도 동작)
      final bytes = await widget.imageFile.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);

      // 1. OCR: 사진에서 일본어 줄 단위 텍스트 추출
      final lines = await _ocrService.extractTextLines(bytes);

      if (lines.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '텍스트를 인식하지 못했습니다. 더 선명하게 다시 찍어보세요.';
        });
        return;
      }

      // 2. 번역: 인식된 각 줄을 한국어로 번역
      final translated = await _translationService.translateLines(lines);

      // 3. 원문/번역을 묶어서 MenuItem 리스트로 구성
      final items = <MenuItem>[];
      for (var i = 0; i < lines.length; i++) {
        items.add(MenuItem.fromTexts(
          original: lines[i],
          translated: i < translated.length ? translated[i] : '',
        ));
      }

      if (!mounted) return;
      setState(() {
        _items = items;
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
      body: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _imageBytes == null
                ? const ColoredBox(color: Colors.black12)
                : Image.memory(_imageBytes!, fit: BoxFit.cover),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
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

    if (_items.isEmpty) {
      return const Center(child: Text('인식된 항목이 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _MenuItemCard(item: item);
      },
    );
  }
}

/// 원문(일본어)과 번역(한국어)을 함께 보여주는 카드.
/// 가격으로 추정되는 줄은 색을 다르게 표시해서 구분감을 줌.
/// (요리명/가격 구조화 파싱은 2단계 이후 고도화 지점)
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: item.isLikelyPrice ? Colors.amber.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.originalText,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              item.translatedText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
