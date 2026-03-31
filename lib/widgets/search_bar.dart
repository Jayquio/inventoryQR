import 'package:flutter/material.dart';
import '../core/constants.dart';

class DebouncedSearchBar extends StatefulWidget {
  const DebouncedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  late final Debouncer _debouncer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UIConstants.radius),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            setState(() => _loading = true);
            _debouncer(() {
              widget.onChanged(value);
              if (mounted) setState(() => _loading = false);
            });
          },
        ),
        if (_loading)
          const Positioned(
            right: 8,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}
