import 'package:suara_surabaya_admin/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text('The page you are looking for does not exist.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            )
          ],
        ),
      ),
    );
  }
}