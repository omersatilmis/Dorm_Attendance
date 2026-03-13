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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      if (mounted) {
        context.go('/home');
      }
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
                    title: 'Hoş Geldiniz',
                    subtitle: 'Lütfen hesabınıza giriş yapın',
                    icon: Icons.lock_outline,
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
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (authProvider.errorMessage != null)
                                AuthErrorWidget(
                                  message: authProvider.errorMessage!,
                                ),
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
                              const SizedBox(height: 16),
                              AuthFooterWidget(
                                questionText: 'Hesabınız yok mu?',
                                actionText: 'Kayıt Ol',
                                onPressed: () => context.go('/register'),
                              ),
                            ],
                          ),
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
