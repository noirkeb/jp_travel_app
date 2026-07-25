import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jp_travel_app/models/ocr_block.dart';

/// 이미지 바이트를 Google Cloud Vision(DOCUMENT_TEXT_DETECTION)으로 분석해서
/// "줄 단위 텍스트 + 원본 이미지 상의 위치(좌표)"를 반환한다.
/// 위치 정보를 함께 받아야 번역을 원본 사진 위 같은 자리에 얹을 수 있다.
class OcrService {
  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';

  Future<OcrResult> detectLines(Uint8List bytes) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY가 .env에 설정되지 않았습니다.');
    }

    final base64Image = base64Encode(bytes);
    final requestBody = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "DOCUMENT_TEXT_DETECTION"} // 구조(블록/줄/좌표) 정보 포함
          ],
          "imageContext": {
            "languageHints": ["ja"] // 일본어 특화
          }
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$_endpoint?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('OCR 요청 실패: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final responses = data['responses'] as List<dynamic>?;
    if (responses == null || responses.isEmpty) {
      return OcrResult(imageWidth: 0, imageHeight: 0, blocks: []);
    }

    final fta = responses[0]['fullTextAnnotation'];
    if (fta == null) {
      return OcrResult(imageWidth: 0, imageHeight: 0, blocks: []);
    }

    final lines = <OcrBlock>[];
    int imgW = 0, imgH = 0;

    for (final page in (fta['pages'] as List<dynamic>? ?? [])) {
      imgW = (page['width'] as num?)?.toInt() ?? imgW;
      imgH = (page['height'] as num?)?.toInt() ?? imgH;

      for (final block in (page['blocks'] as List<dynamic>? ?? [])) {
        for (final para in (block['paragraphs'] as List<dynamic>? ?? [])) {
          // 문단 안의 단어들을 줄바꿈(LINE_BREAK) 기준으로 "줄"로 묶는다.
          final buf = StringBuffer();
          Rect? lineBox;

          for (final word in (para['words'] as List<dynamic>? ?? [])) {
            final syms = word['symbols'] as List<dynamic>? ?? [];
            for (final s in syms) {
              buf.write(s['text'] ?? '');
            }
            final wb = _rectFromBoundingBox(word['boundingBox']);
            if (wb != null) {
              lineBox = lineBox == null ? wb : lineBox.expandToInclude(wb);
            }
            final brk = _lastBreakType(syms);
            if (brk == 'LINE_BREAK' || brk == 'EOL_SURE_SPACE') {
              _addLine(lines, buf, lineBox);
              buf.clear();
              lineBox = null;
            } else if (brk == 'SPACE') {
              buf.write(' ');
            }
          }
          _addLine(lines, buf, lineBox); // 문단 끝 잔여 줄
        }
      }
    }

    return OcrResult(imageWidth: imgW, imageHeight: imgH, blocks: lines);
  }

  /// 단어의 마지막 심볼에 붙은 줄바꿈/공백 종류를 안전하게 꺼낸다.
  String? _lastBreakType(List<dynamic> syms) {
    if (syms.isEmpty) return null;
    final prop = syms.last['property'];
    if (prop == null) return null;
    final db = prop['detectedBreak'];
    if (db == null) return null;
    return db['type'] as String?;
  }

  void _addLine(List<OcrBlock> lines, StringBuffer buf, Rect? box) {
    final text = buf.toString().trim();
    if (text.isNotEmpty && box != null) {
      lines.add(OcrBlock(text: text, box: box));
    }
  }

  Rect? _rectFromBoundingBox(dynamic bb) {
    if (bb == null) return null;
    final verts = bb['vertices'] as List<dynamic>?;
    if (verts == null || verts.isEmpty) return null;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final v in verts) {
      final x = (v['x'] as num?)?.toDouble() ?? 0;
      final y = (v['y'] as num?)?.toDouble() ?? 0;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    if (maxX <= minX || maxY <= minY) return null;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
