import 'package:flutter/material.dart';

class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.child,
    this.onTap,
    this.baseElevation = 6,
    this.hoverElevation = 10,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double baseElevation;
  final double hoverElevation;
  final BorderRadius? borderRadius;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(_hover ? 1.02 : 1.0, _hover ? 1.02 : 1.0, 1.0),
        child: Card(
          elevation: _hover ? widget.hoverElevation : widget.baseElevation,
          shape: RoundedRectangleBorder(borderRadius: radius),
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
