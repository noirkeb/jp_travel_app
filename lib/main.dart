import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jp_travel_app/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env'); // API 키 로드 (.env.example 참고해서 .env 생성 필요)
  runApp(const JpTravelApp());
}

class JpTravelApp extends StatelessWidget {
  const JpTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일본여행 메뉴판 번역',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
