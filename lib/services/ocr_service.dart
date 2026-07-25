import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 이미지 바이트를 넘기면 Google Cloud Vision API로 텍스트를 인식해서
/// 줄 단위 리스트로 반환하는 서비스.
/// (File이 아닌 바이트를 받아 웹/모바일 모두에서 동작함)
class OcrService {
  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';

  Future<List<String>> extractTextLines(Uint8List bytes) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY가 .env에 설정되지 않았습니다.');
    }

    final base64Image = base64Encode(bytes);

    final requestBody = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ],
          "imageContext": {
            "languageHints": ["ja"] // 일본어 특화 - 핵심 차별점
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

    final data = jsonDecode(response.body);
    final responses = data['responses'] as List<dynamic>?;

    if (responses == null || responses.isEmpty) {
      return [];
    }

    final annotations = responses[0]['textAnnotations'];

    if (annotations == null || annotations.isEmpty) {
      return [];
    }

    // 첫 번째 항목은 전체 텍스트 통짜본이라, fullText를 줄바꿈 기준으로 분리해서 사용
    final fullText = annotations[0]['description'] as String;
    return fullText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
