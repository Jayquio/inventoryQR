import 'dart:async';
import 'package:flutter/material.dart';

class UIConstants {
  static const double padding = 16.0;
  static const double radius = 12.0;
  static const Duration debounceDuration = Duration(milliseconds: 300);
}

class AppRoutes {
  static const String viewInstruments = '/view_instruments';
  static const String manageRequests = '/manage_requests';
  static const String settings = '/settings';
  static const String trackStatus = '/track_status';
}

class Breakpoints {
  static const double xs = 320;
  static const double sm = 768;
  static const double md = 1024;
  static const double lg = 1440;
}

class R {
  static double text(double base, double width) {
    if (width < Breakpoints.xs) return base * 0.9;
    if (width < Breakpoints.sm) return base;
    if (width < Breakpoints.md) return base * 1.05;
    return base * 1.12;
  }

  static EdgeInsets pad(double width) {
    if (width < Breakpoints.xs) return const EdgeInsets.all(12);
    if (width < Breakpoints.sm) return const EdgeInsets.all(16);
    if (width < Breakpoints.md) return const EdgeInsets.all(20);
    return const EdgeInsets.all(24);
    }

  static int columns(double width, {int xs = 1, int sm = 2, int md = 3, int lg = 4}) {
    if (width < 420) return xs;
    if (width < Breakpoints.sm) return sm;
    if (width < Breakpoints.md) return md;
    return lg;
  }

  static double tileAspect(double width) {
    if (width < 420) return 0.95;
    if (width < Breakpoints.sm) return 1.0;
    if (width < Breakpoints.md) return 1.15;
    return 1.25;
  }
}

class Debouncer {
  Debouncer({this.duration = UIConstants.debounceDuration});

  final Duration duration;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
