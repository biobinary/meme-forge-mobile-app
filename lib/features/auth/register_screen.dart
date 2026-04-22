import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Semua field harus diisi!';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password minimal 6 karakter!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      
      final authService = ref.read(authServiceProvider);
      await authService.registerWithEmailAndPassword(username, email, password);

      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Terjadi kesalahan saat registrasi';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'CREATE ACCOUNT',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar untuk menyimpan dan membagikan karyamu!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error, width: 2),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),

                // Username Field
                _NeoTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_rounded,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                // Email Field
                _NeoTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),

                // Password Field
                _NeoTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: true,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 32),

                // Register Button
                _NeoButton(
                  text: 'DAFTAR SEKARANG',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _register,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),

                // Login Link
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Sudah punya akun? Masuk di sini',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Copy of NeoTextField from LoginScreen
class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ColorScheme colorScheme;

  const _NeoTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.onSurface, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.onSurface, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
      ),
      style: TextStyle(color: colorScheme.onSurface),
    );
  }
}

// Copy of NeoButton from LoginScreen
class _NeoButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _NeoButton({
    required this.text,
    this.isLoading = false,
    this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey : colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface, width: 2),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.onSurface,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
