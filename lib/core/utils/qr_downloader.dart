// lib/core/utils/qr_downloader.dart

export 'qr_download_stub.dart'
    if (dart.library.html) 'qr_downloader_web.dart'
    if (dart.library.io) 'qr_downloader_mobile.dart';
