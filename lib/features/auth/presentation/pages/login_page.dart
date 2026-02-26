import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_error_widget.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      // Role göre yönlendirme mantığı buraya gelecek
      // Şimdilik ana sayfaya gitsin
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
              title: 'Hoş Geldiniz',
              subtitle: 'Lütfen hesabınıza giriş yapın',
              icon: Icons.lock_outline,
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
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Giriş Yap',
                      onPressed: _login,
                      isLoading: authProvider.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AuthFooterWidget(
            questionText: 'Hesabınız yok mu?',
            actionText: 'Kayıt Ol',
            onPressed: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}
