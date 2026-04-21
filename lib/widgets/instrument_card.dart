import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Text-only instrument card — no image placeholders.
class InstrumentCard extends StatefulWidget {
  const InstrumentCard({
    super.key,
    required this.instrument,
    this.onTap,
    this.highlight,
    this.userRole = 'Student',
  });

  final Instrument instrument;
  final VoidCallback? onTap;
  final String? highlight;
  final String userRole;

  @override
  State<InstrumentCard> createState() => _InstrumentCardState();
}

class _InstrumentCardState extends State<InstrumentCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final inst = widget.instrument;
    final available = inst.available > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
            _hover ? 1.02 : 1.0, _hover ? 1.02 : 1.0, 1.0),
        child: Card(
          elevation: _hover ? 4 : 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.radius)),
          child: InkWell(
            borderRadius: BorderRadius.circular(UIConstants.radius),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category icon + status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(inst.category),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inst.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _statusDot(available),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      children: _highlightSpans(
                          inst.name, widget.highlight),
                    ),
                  ),
                  if (inst.serialNumber != null &&
                      inst.serialNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'S/N: ${inst.serialNumber}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                  const Spacer(),
                  // Bottom: qty
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: available
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${inst.available}/${inst.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: available
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      Text(
                        inst.location,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusDot(bool available) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: available ? Colors.green : Colors.red.shade400,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (available ? Colors.green : Colors.red).withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('glass') || c.contains('microscop')) {
      return Icons.science_outlined;
    }
    if (c.contains('chem') || c.contains('reagent')) {
      return Icons.biotech_outlined;
    }
    if (c.contains('heat') || c.contains('steril')) {
      return Icons.local_fire_department_outlined;
    }
    return Icons.precision_manufacturing_outlined;
  }

  List<TextSpan> _highlightSpans(String text, String? term) {
    if (term == null || term.isEmpty) return [TextSpan(text: text)];
    final lowerText = text.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final idx = lowerText.indexOf(lowerTerm);
    if (idx < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(
          text: text.substring(idx, idx + lowerTerm.length),
          style: const TextStyle(backgroundColor: Color(0xFFFFF59D))),
      TextSpan(text: text.substring(idx + lowerTerm.length)),
    ];
  }
}