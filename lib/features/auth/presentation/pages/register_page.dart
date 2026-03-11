import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input_field.dart';
import 'package:yurt_yoklama/core/utils/snackbar_service.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_error_widget.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedProfileId;
  List<Map<String, dynamic>> _availableProfiles = [];
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await context
          .read<AuthProvider>()
          .fetchAvailableProfiles();
      debugPrint('📋 Yüklenen profil sayısı: ${profiles.length}');
      for (var p in profiles) {
        debugPrint(
          '  → ${p['full_name']} (${p['role']}) - registered: ${p['is_registered']}',
        );
      }
      if (mounted) {
        setState(() {
          _availableProfiles = profiles;
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Profil yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackbarService.showError(context, 'Şifreler eşleşmiyor');
      return;
    }

    final success = await context.read<AuthProvider>().registerWithProfile(
      profileId: _selectedProfileId!,
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;
          final headerHeight = isLargeScreen
              ? 200.0
              : (constraints.maxHeight * 0.35).clamp(150.0, 300.0);

          Widget content = CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: headerHeight,
                  child: const AuthHeaderWidget(
                    title: 'Yeni Hesap',
                    subtitle: 'İsmini seç ve e-posta ile hesabını oluştur',
                    icon: Icons.person_add_outlined,
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authProvider.errorMessage != null)
                              AuthErrorWidget(
                                message: authProvider.errorMessage!,
                              ),
                            if (_isLoadingProfiles)
                              const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              )
                            else if (_availableProfiles.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Kayıt yapılabilecek profil bulunamadı.\nAdmin tarafından eklenmesi gerekiyor.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else ...[
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Adınızı Seçin',
                                  prefixIcon: Icon(Icons.person_search),
                                ),
                                initialValue: _selectedProfileId,
                                items: _availableProfiles.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p['id'].toString(),
                                    child: Text(
                                      '${p['full_name']} (${p['role']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedProfileId = val),
                                validator: (v) =>
                                    v == null ? 'Lütfen isminizi seçin' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            AppInputField(
                              label: 'E-posta',
                              hint: 'example@mail.com',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Geçerli bir e-posta girin'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'Şifre',
                              hint: '••••••••',
                              icon: Icons.password_outlined,
                              controller: _passwordController,
                              isPassword: true,
                              validator: (v) => v == null || v.length < 6
                                  ? 'En az 6 karakter girin'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'Şifreyi Onayla',
                              hint: '••••••••',
                              icon: Icons.password_outlined,
                              controller: _confirmPasswordController,
                              isPassword: true,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Şifreyi tekrar girin'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Kayıt Ol ve Eşleş',
                              onPressed: _handleRegister,
                              isLoading: authProvider.isLoading,
                            ),
                            const SizedBox(height: 16),
                            AuthFooterWidget(
                              questionText: 'Zaten hesabınız var mı?',
                              actionText: 'Giriş Yap',
                              onPressed: () => context.go('/login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isLargeScreen) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                clipBehavior: Clip.antiAlias,
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}
