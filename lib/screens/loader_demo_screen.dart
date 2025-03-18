import 'package:flutter/material.dart';
import '../widgets/circular_loader.dart';

class LoaderDemoScreen extends StatelessWidget {
  const LoaderDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loader Demo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
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
        ),
      ),
    );
  }
}
