import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jp_travel_app/screens/result_screen.dart';

/// 첫 화면: 카메라 촬영 / 사진 선택 / 파일 선택 중 하나를 고른다.
/// (예전처럼 열자마자 카메라가 켜지지 않게 선택 화면을 먼저 보여줌)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Uint8List?> _fromImagePicker(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    return picked == null ? null : await picked.readAsBytes();
  }

  Future<Uint8List?> _fromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.bytes;
  }

  Future<void> _pick(
      BuildContext context, Future<Uint8List?> Function() getBytes) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await getBytes();
      if (bytes == null) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => ResultScreen(imageBytes: bytes)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('이미지를 불러오지 못했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.translate, size: 64, color: scheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    '일본 메뉴판 번역',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '메뉴판을 촬영하거나 사진·파일을 선택하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: () =>
                        _pick(context, () => _fromImagePicker(ImageSource.camera)),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('카메라로 촬영'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _pick(
                        context, () => _fromImagePicker(ImageSource.gallery)),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('사진에서 선택'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _pick(context, _fromFile),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('파일 선택'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
