// 메뉴판 번역 앱 기본 스모크 테스트.
// 첫 화면(홈)이 뜨고 카메라/사진/파일 선택 버튼이 보이는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jp_travel_app/screens/home_screen.dart';

void main() {
  testWidgets('홈 화면에 촬영/선택 버튼이 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('카메라로 촬영'), findsOneWidget);
    expect(find.text('사진에서 선택'), findsOneWidget);
    expect(find.text('파일 선택'), findsOneWidget);
  });
}
