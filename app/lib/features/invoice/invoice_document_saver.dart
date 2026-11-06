import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

typedef InvoiceSaveFile = Future<String> Function(String name, Uint8List bytes);

class InvoiceDocumentSaver {
  InvoiceDocumentSaver({InvoiceSaveFile? saveFile})
    : _saveFile = saveFile ?? _saveToDevice;
  final InvoiceSaveFile _saveFile;
  Future<String> save(int invoiceId, Uint8List bytes) =>
      _saveFile('invoice-$invoiceId', bytes);

  static Future<String> _saveToDevice(String name, Uint8List bytes) =>
      FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
}
