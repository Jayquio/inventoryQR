// lib/core/utils/qr_download_stub.dart

import 'package:flutter/foundation.dart';

Future<void> downloadQrFile(String payload, String fileName) async {
  // This is a stub that will be overridden by platform-specific implementations.
  debugPrint('Downloading $fileName on unknown platform...');
}
