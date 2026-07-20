import 'dart:typed_data';

import 'package:dazhongdianping_app/features/user/privacy_export_saver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy export saver uses a stable zip file name', () async {
    String? savedName;
    Uint8List? savedBytes;
    final saver = PrivacyExportSaver(
      saveFile: (name, bytes) async {
        savedName = name;
        savedBytes = bytes;
        return '/downloads/$name.zip';
      },
    );

    final path = await saver.save(8, Uint8List.fromList([1, 2, 3]));

    expect(savedName, 'privacy-export-8');
    expect(savedBytes, [1, 2, 3]);
    expect(path, '/downloads/privacy-export-8.zip');
  });
}
