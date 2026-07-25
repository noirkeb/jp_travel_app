import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jp_travel_app/data/menu_dictionary.dart';

/// 일본어 메뉴 줄들을 한국어로 번역.
///
/// 하이브리드 방식:
///  1) 먼저 요리명 사전으로 시도 (자주 나오는 메뉴는 자연스럽게)
///  2) 사전으로 안 되는 줄만 모아 Google Translation API로 배치 번역
/// OCR(Vision)과 같은 Google API 키(GOOGLE_API_KEY)를 사용한다.
class TranslationService {
  static const _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  Future<List<String>> translateLines(List<String> lines) async {
    final results = List<String>.filled(lines.length, '');
    final pendingIndexes = <int>[];
    final pendingTexts = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final fromDict = MenuDictionary.tryTranslate(lines[i]);
      if (fromDict != null) {
        results[i] = fromDict;
      } else {
        pendingIndexes.add(i);
        pendingTexts.add(lines[i]);
      }
    }

    if (pendingTexts.isNotEmpty) {
      final translated = await _googleTranslate(pendingTexts);
      for (var k = 0; k < pendingIndexes.length; k++) {
        results[pendingIndexes[k]] =
            k < translated.length ? translated[k] : '';
      }
    }

    return results;
  }

  /// 여러 문장을 한 번의 요청으로 배치 번역.
  Future<List<String>> _googleTranslate(List<String> texts) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_API_KEY가 .env에 설정되지 않았습니다.');
    }

    final response = await http.post(
      Uri.parse('$_endpoint?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': texts,
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
}
