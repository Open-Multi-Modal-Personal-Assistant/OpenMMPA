import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:mime/mime.dart';

enum MFileType {
  image,
  video,
  audio,
  pdf,
  other,
}

/// An XFile together with a MIME type
class MFile {
  MFile(this.xFile, this.mimeType) {
    fileType = switch (mimeType.split('/')[0]) {
      'image' => MFileType.image,
      'video' => MFileType.video,
      'audio' => MFileType.audio,
      _ => mimeType.endsWith('/pdf') ? MFileType.pdf : MFileType.other,
    };
  }

  final XFile xFile;
  String mimeType = '';
  late MFileType fileType;

  static Future<String> obtainMimeType(
    XFile xFile, {
    bool contentInspection = true,
  }) async {
    final firstKb = await xFile.openRead(0, 1024).first;
    final mime = lookupMimeType(xFile.path, headerBytes: firstKb) ?? '';
    log('MIME for ${xFile.path}: $mime');
    return mime;
  }

  bool mimeTypeIsUnknown() {
    return mimeType.isEmpty ||
        mimeType.endsWith('unknown') ||
        mimeType == 'application/octet-stream' ||
        mimeType == 'application/binary';
  }

  Future<Uint8List> content() async {
    return xFile.readAsBytes();
  }
}
