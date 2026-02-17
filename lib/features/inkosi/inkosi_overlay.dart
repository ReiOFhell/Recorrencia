import 'package:flutter/material.dart';

class InkosiOverlay extends StatelessWidget {
  const InkosiOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: Text(message, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
