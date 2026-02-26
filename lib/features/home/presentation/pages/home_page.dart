import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yurt Yoklama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hoş Geldin, ${user?['full_name'] ?? 'Kullanıcı'}'),
            Text('Rolün: ${user?['role'] ?? 'Bilinmiyor'}'),
            const SizedBox(height: 20),
            if (authProvider.isAnyAdmin)
              ElevatedButton(
                onPressed: () {
                  // Admin işlemleri
                },
                child: const Text('Yönetim Paneli'),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Yoklama alma sayfası
              },
              child: const Text('Yoklama Al'),
            ),
          ],
        ),
      ),
    );
  }
}
