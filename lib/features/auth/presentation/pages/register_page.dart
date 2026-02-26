import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input_field.dart';
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

  Future<void> _loadProfiles() async {
    final profiles = await context
        .read<AuthProvider>()
        .fetchAvailableProfiles();
    if (mounted) {
      setState(() {
        _availableProfiles = profiles;
        _isLoadingProfiles = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Şifreler eşleşmiyor')));
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
      body: Column(
        children: [
          const Expanded(
            flex: 3,
            child: AuthHeaderWidget(
              title: 'Yeni Hesap',
              subtitle: 'İsmini seç ve e-posta ile hesabını oluştur',
              icon: Icons.person_add_outlined,
            ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (authProvider.errorMessage != null)
                      AuthErrorWidget(message: authProvider.errorMessage!),

                    if (_isLoadingProfiles)
                      const CircularProgressIndicator()
                    else ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Adınızı Seçin',
                          prefixIcon: Icon(Icons.person_search),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProfileId,
                        items: _availableProfiles.map((p) {
                          return DropdownMenuItem<String>(
                            value: p['id'].toString(),
                            child: Text(p['full_name']),
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
                  ],
                ),
              ),
            ),
          ),
          AuthFooterWidget(
            questionText: 'Zaten hesabınız var mı?',
            actionText: 'Giriş Yap',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
