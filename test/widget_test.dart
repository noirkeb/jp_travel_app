// 메뉴판 번역 앱 기본 스모크 테스트.
// 1단계에서는 앱이 정상적으로 뜨고 첫 화면(카메라 초기화 중 로딩)이
// 그려지는지만 확인한다. OCR/번역 등 네트워크 로직은 별도 단위 테스트로 분리 예정.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jp_travel_app/screens/camera_screen.dart';

void main() {
  testWidgets('첫 화면이 로딩 인디케이터와 함께 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CameraScreen()));

    // 카메라 초기화 전에는 로딩 스피너가 보여야 한다.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
