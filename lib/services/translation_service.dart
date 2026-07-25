import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 일본어 문장 리스트를 받아 Papago API로 한국어 번역 리스트를 반환.
/// 줄 단위로 여러 번 호출하면 느리고 비용도 늘어나므로,
/// 실제로는 배치 처리나 캐싱을 나중에 추가하는 게 좋음 (2단계 이후 최적화 포인트).
class TranslationService {
  // 2024년 네이버클라우드 엔드포인트 변경: naveropenapi.apigw → papago.apigw
  // (구 주소는 403 Forbidden 반환)
  static const _endpoint =
      'https://papago.apigw.ntruss.com/nmt/v1/translation';

  Future<String> translateJaToKo(String text) async {
    if (text.trim().isEmpty) return '';

    final clientId = dotenv.env['PAPAGO_CLIENT_ID'];
    final clientSecret = dotenv.env['PAPAGO_CLIENT_SECRET'];

    if (clientId == null || clientSecret == null) {
      throw Exception('Papago API 키가 .env에 설정되지 않았습니다.');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId,
        'X-NCP-APIGW-API-KEY': clientSecret,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'source': 'ja',
        'target': 'ko',
        'text': text,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('번역 요청 실패: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final translatedText = data['message']?['result']?['translatedText'];

    if (translatedText == null) {
      throw Exception('번역 응답 형식이 올바르지 않습니다: ${response.body}');
    }

    return translatedText as String;
  }

  /// 여러 줄을 순차 번역. 1단계는 단순 반복 호출로 시작하고,
  /// 속도가 문제되면 이후 Future.wait 병렬화나 배치 API로 개선.
  Future<List<String>> translateLines(List<String> lines) async {
    final results = <String>[];
    for (final line in lines) {
      final translated = await translateJaToKo(line);
      results.add(translated);
    }
    return results;
  }
}
