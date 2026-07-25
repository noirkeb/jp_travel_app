import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 일본어 문장 리스트를 받아 Google Cloud Translation API로 한국어 번역 리스트를 반환.
///
/// 원래 Papago를 썼으나, Papago는 브라우저에서 CORS로 직접 호출이 막혀
/// 웹(링크) 배포가 불가능했다. 그래서 브라우저 호출이 되는 Google 번역으로 교체.
/// OCR(Vision)과 동일한 Google API 키(GOOGLE_API_KEY)를 사용한다.
class TranslationService {
  static const _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  Future<String> translateJaToKo(String text) async {
    if (text.trim().isEmpty) return '';

    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY가 .env에 설정되지 않았습니다.');
    }

    final response = await http.post(
      Uri.parse('$_endpoint?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
        'source': 'ja',
        'target': 'ko',
        'format': 'text',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('번역 요청 실패: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final translated = data['data']?['translations']?[0]?['translatedText'];

    if (translated == null) {
      throw Exception('번역 응답 형식이 올바르지 않습니다: ${response.body}');
    }

    return translated as String;
  }

  /// 여러 줄을 순차 번역. 1단계는 단순 반복 호출로 시작.
  /// (개선 여지: Google 번역은 q를 배열로 한 번에 여러 개 보낼 수 있어
  ///  나중에 배치 호출로 속도 최적화 가능)
  Future<List<String>> translateLines(List<String> lines) async {
    final results = <String>[];
    for (final line in lines) {
      final translated = await translateJaToKo(line);
      results.add(translated);
    }
    return results;
  }
}
