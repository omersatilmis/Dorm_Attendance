import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Lütfen giriş yapın.')),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Beklenmedik bir hata oluştu');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            flex: 3,
            child: AuthHeaderWidget(
              title: 'Yeni Hesap',
              subtitle: 'Aramıza katılmak için formu doldur',
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
                    if (_errorMessage != null)
                      AuthErrorWidget(message: _errorMessage!),
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
                      text: 'Kayıt Ol',
                      onPressed: _register,
                      isLoading: _isLoading,
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
