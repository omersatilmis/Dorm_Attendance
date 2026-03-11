import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/core/utils/snackbar_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptName();
    });
  }

  void _checkAndPromptName() {
    if (_hasPrompted) return;
    final user = context.read<AuthProvider>().userProfile;
    // Eğer isim tam olarak buysa (admin varsayılan ismiyse)
    if (user != null && user['full_name'] == 'Yurt Müdürü') {
      _hasPrompted = true;
      _showMandatoryNamePrompt(context);
    }
  }

  void _showMandatoryNamePrompt(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text(
              'İsminizi Giriniz',
              style: TextStyle(color: AppColors.darkTextPrimary),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                filled: true,
                fillColor: AppColors.darkSurfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    final nav = Navigator.of(dialogContext);
                    final success = await context
                        .read<AuthProvider>()
                        .updateProfileName(newName);
                    if (success) {
                      nav.pop();
                      if (context.mounted) {
                        SnackbarService.showSuccess(context, 'İsim kaydedildi');
                      }
                    } else {
                      if (context.mounted) {
                        SnackbarService.showError(
                          context,
                          'İsim kaydedilemedi',
                        );
                      }
                    }
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profili Düzenle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  filled: true,
                  fillColor: AppColors.darkSurfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    final nav = Navigator.of(sheetContext);
                    final success = await context
                        .read<AuthProvider>()
                        .updateProfileName(newName);
                    nav.pop();
                    if (success) {
                      if (context.mounted) {
                        SnackbarService.showSuccess(
                          context,
                          'İsim güncellendi',
                        );
                      }
                    } else {
                      if (context.mounted) {
                        SnackbarService.showError(
                          context,
                          'İsim güncellenemedi',
                        );
                      }
                    }
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Hoş Geldiniz, ${user?['full_name'] ?? 'Kullanıcı'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showEditProfileSheet(context, user?['full_name'] ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rol: ${user?['role'] ?? 'Bilinmiyor'}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 48),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (authProvider.isAnyAdmin) ...[
                    _buildMenuButton(
                      context,
                      label: 'Yönetim Paneli',
                      icon: Icons.admin_panel_settings_outlined,
                      route: '/management',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildMenuButton(
                    context,
                    label: 'Yoklama Al',
                    icon: Icons.how_to_reg_outlined,
                    route: '/attendance',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () => context.push(route),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
