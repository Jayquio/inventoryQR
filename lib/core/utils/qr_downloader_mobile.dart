// lib/core/utils/qr_downloader_mobile.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr/qr.dart';

Future<void> downloadQrFile(String payload, String fileName) async {
  try {
    // 1. Check/Request Permissions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        debugPrint('Storage permission denied');
        return;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        debugPrint('Photos permission denied');
        return;
      }
    }

    // 2. Generate QR Data Matrix
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final int modules = qrCode.moduleCount;
    
    const double moduleSize = 20.0;
    const int quietZone = 4;
    final double canvasSize = (modules + quietZone * 2) * moduleSize;

    // 3. Draw to Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;
    
    // Draw white background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasSize, canvasSize), paint);
    
    // Draw black modules
    paint.color = Colors.black;
    for (int x = 0; x < modules; x++) {
      for (int y = 0; y < modules; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (x + quietZone) * moduleSize,
              (y + quietZone) * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }

    // 4. Convert to Image Bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to generate image bytes');
    final bytes = byteData.buffer.asUint8List();

    // 5. Save to Gallery
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/$fileName';
    final file = File(tempPath);
    await file.writeAsBytes(bytes);

    await Gal.putImage(tempPath);
    
    debugPrint('QR Code saved to gallery: $tempPath');
    
    // Clean up temp file
    if (await file.exists()) await file.delete();
    
  } catch (e) {
    debugPrint('Error downloading QR on mobile: $e');
  }
}
