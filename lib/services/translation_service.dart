import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 일본어 문장들을 Google Cloud Translation API로 한국어로 번역.
///
/// Papago는 브라우저 CORS로 웹에서 막혀 Google 번역으로 교체됨.
/// OCR(Vision)과 같은 Google API 키(GOOGLE_API_KEY)를 사용한다.
class TranslationService {
  static const _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  String get _apiKey {
    final key = dotenv.env['GOOGLE_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GOOGLE_API_KEY가 .env에 설정되지 않았습니다.');
    }
    return key;
  }

  /// 여러 줄을 한 번의 요청으로 배치 번역 (줄마다 개별 호출보다 훨씬 빠름).
  /// 입력 순서와 동일한 순서로 번역 결과를 반환.
  Future<List<String>> translateLines(List<String> lines) async {
    if (lines.isEmpty) return [];

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': lines, // 배열로 여러 개 한 번에 전송
        'source': 'ja',
        'target': 'ko',
        'format': 'text',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('번역 요청 실패: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final translations = data['data']?['translations'] as List<dynamic>?;
    if (translations == null) {
      throw Exception('번역 응답 형식이 올바르지 않습니다: ${response.body}');
    }

    return translations
        .map((t) => (t['translatedText'] ?? '').toString())
        .toList();
  }

  /// 단일 문장 번역 (편의용).
  Future<String> translateJaToKo(String text) async {
    if (text.trim().isEmpty) return '';
    final result = await translateLines([text]);
    return result.isNotEmpty ? result.first : '';
  }
}
