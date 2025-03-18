import 'package:flutter/material.dart';
import 'circular_loader.dart';

/// Demo widget showcasing the CircularLoader with different configurations
class LoaderDemo extends StatelessWidget {
  const LoaderDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Default Size (100)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const CircularLoader(),

          const SizedBox(height: 40),

          const Text(
            'Small Size (50)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const CircularLoader(size: 50, strokeWidth: 5),

          const SizedBox(height: 40),

          const Text(
            'Large Size (150)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const CircularLoader(size: 150, strokeWidth: 15),

          const SizedBox(height: 40),

          const Text(
            'Fast Animation (1s)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const CircularLoader(duration: 1000),
        ],
      ),
    );
  }
}
