import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UnderConstructionScreen extends StatelessWidget {
  const UnderConstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    return Expanded(
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 7),
          TextStyleExample(
              name: 'Under construction', style: textTheme.titleLarge!),
          Lottie.asset(
            'assets/underconstruction.json',
            width: 300,
            height: 300,
            fit: BoxFit.scaleDown,
          ),
        ],
      ),
    );
  }
}

class TextStyleExample extends StatelessWidget {
  const TextStyleExample({
    super.key,
    required this.name,
    required this.style,
  });

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(name, style: style),
    );
  }
}
