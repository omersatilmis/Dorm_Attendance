import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagementDashboard extends StatelessWidget {
  const ManagementDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildItem(
            context,
            title: 'Hoca Yönetimi',
            subtitle: 'Yeni hoca ekle veya listele',
            icon: Icons.person_add,
            onTap: () => context.push('/management/teachers'),
          ),
          const SizedBox(height: 12),
          _buildItem(
            context,
            title: 'Ders Grupları',
            subtitle: 'Grup oluştur ve hoca ata',
            icon: Icons.group_work,
            onTap: () => context.push('/management/groups'),
          ),
          const SizedBox(height: 12),
          _buildItem(
            context,
            title: 'Öğrenci Yönetimi',
            subtitle: 'Öğrenci ekle ve grup ata',
            icon: Icons.people,
            onTap: () => context.push('/management/students'),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
