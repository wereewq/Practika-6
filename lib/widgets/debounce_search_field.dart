import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedSearchField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String hintText;
  final Duration debounceDuration;

  const DebouncedSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintText = 'Поиск...',
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant DebouncedSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(text);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _debounceTimer?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              )
            : null,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: _onTextChanged,
    );
  }
}
