import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            const SizedBox(height: 30),
            if (authProvider.isAnyAdmin) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () => context.push('/management'),
                label: const Text('Yönetim Paneli'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.how_to_reg),
              onPressed: () => context.push('/attendance'),
              label: const Text('Yoklama Al'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
