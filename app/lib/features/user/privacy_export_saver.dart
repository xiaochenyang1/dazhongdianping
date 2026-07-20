import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

typedef PrivacySaveFile = Future<String> Function(String name, Uint8List bytes);

class PrivacyExportSaver {
  PrivacyExportSaver({PrivacySaveFile? saveFile})
    : _saveFile = saveFile ?? _saveToDevice;

  final PrivacySaveFile _saveFile;

  Future<String> save(int taskId, Uint8List bytes) {
    return _saveFile('privacy-export-$taskId', bytes);
  }

  static Future<String> _saveToDevice(String name, Uint8List bytes) {
    return FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: 'zip',
      mimeType: MimeType.zip,
    );
  }
}
