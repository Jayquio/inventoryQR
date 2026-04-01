// lib/core/utils/qr_downloader_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: depend_on_referenced_packages
import 'package:qr/qr.dart';

Future<void> downloadQrFile(String payload, String fileName) async {
  try {
    const int moduleSize = 10; // pixels per QR module
    const int quietZone = 4;   // modules of white border

    // Generate QR code matrix
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final int modules = qrCode.moduleCount;
    final int canvasSize = (modules + quietZone * 2) * moduleSize;

    // Create canvas and draw
    final canvas = html.CanvasElement(width: canvasSize, height: canvasSize);
    final ctx = canvas.context2D;

    // White background
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, canvasSize, canvasSize);

    // Draw QR modules
    ctx.fillStyle = '#000000';
    for (int x = 0; x < modules; x++) {
      for (int y = 0; y < modules; y++) {
        if (qrImage.isDark(y, x)) {
          final px = (x + quietZone) * moduleSize;
          final py = (y + quietZone) * moduleSize;
          ctx.fillRect(px, py, moduleSize, moduleSize);
        }
      }
    }

    // Trigger download as PNG
    final String baseName = fileName.split('.').first;
    final dataUrl = canvas.toDataUrl('image/png');
    html.AnchorElement(href: dataUrl)
      ..setAttribute('download', '$baseName.png')
      ..click();
  } catch (e) {
    // Fallback: download as text
    // ignore: avoid_web_libraries_in_flutter
    final blob = html.Blob([payload]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '${fileName.split('.').first}.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

