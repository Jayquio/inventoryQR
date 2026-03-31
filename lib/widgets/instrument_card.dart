import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../core/constants.dart';

class InstrumentCard extends StatefulWidget {
  const InstrumentCard({
    super.key,
    required this.instrument,
    this.onTap,
    this.highlight,
  });

  final Instrument instrument;
  final VoidCallback? onTap;
  final String? highlight;

  @override
  State<InstrumentCard> createState() => _InstrumentCardState();
}

class _InstrumentCardState extends State<InstrumentCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(_hover ? 1.02 : 1.0, _hover ? 1.02 : 1.0, 1.0),
        child: Card(
          elevation: _hover ? 8 : 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.radius)),
          child: InkWell(
            borderRadius: BorderRadius.circular(UIConstants.radius),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(4), // Minimal padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: widget.instrument.imageAsset != null
                          ? Image.asset(
                              widget.instrument.imageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, __) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      children: _highlightSpans(widget.instrument.name, widget.highlight),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusDot(widget.instrument.available > 0),
                      Text(
                        '${widget.instrument.available}/${widget.instrument.quantity}',
                        style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold),
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
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: available ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  

  Widget _placeholder() {
    return Container(
      color: Colors.blueGrey.shade50,
      child: const Center(
        child: Icon(Icons.science, size: 40, color: Colors.blueGrey),
      ),
    );
  }

  List<TextSpan> _highlightSpans(String text, String? term) {
    if (term == null || term.isEmpty) return [TextSpan(text: text)];
    final lowerText = text.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final idx = lowerText.indexOf(lowerTerm);
    if (idx < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(text: text.substring(idx, idx + lowerTerm.length), style: const TextStyle(backgroundColor: Color(0xFFFFF59D))),
      TextSpan(text: text.substring(idx + lowerTerm.length)),
    ];
  }
}
