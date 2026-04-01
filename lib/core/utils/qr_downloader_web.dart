// lib/core/utils/qr_downloader_web.dart

import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:qr/qr.dart';

Future<void> downloadQrFile(String payload, String fileName) async {
  try {
    const int moduleSize = 10;
    const int quietZone = 4;

    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final int modules = qrCode.moduleCount;
    final int canvasSize = (modules + quietZone * 2) * moduleSize;

    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = canvasSize;
    canvas.height = canvasSize;
    
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

    ctx.fillStyle = '#ffffff'.toJS;
    ctx.fillRect(0, 0, canvasSize, canvasSize);

    ctx.fillStyle = '#000000'.toJS;
    for (int x = 0; x < modules; x++) {
      for (int y = 0; y < modules; y++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + quietZone) * moduleSize;
          final py = (y + quietZone) * moduleSize;
          ctx.fillRect(px, py, moduleSize, moduleSize);
        }
      }
    }

    final String baseName = fileName.split('.').first;
    final dataUrl = canvas.toDataURL('image/png');
    
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = dataUrl;
    anchor.download = '$baseName.png';
    anchor.click();
  } catch (e) {
    final blob = web.Blob([payload.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = '${fileName.split('.').first}.txt';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}

