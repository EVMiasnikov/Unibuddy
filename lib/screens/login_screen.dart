import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../widgets/primary_button.dart';
import 'main_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = context.read<AuthController>();
    if (_isRegisterMode) {
      await controller.register(_emailController.text, _passwordController.text);
    } else {
      await controller.login(_emailController.text, _passwordController.text);
    }

    if (!mounted) return;
    if (controller.isLoggedIn) {
      final destination = controller.currentUser!.hasCompletedProfile
          ? const MainScreen()
          : const ProfileSetupScreen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watches the controller so it can show loading/error state.
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                // Keeps the form vertically centered when it fits, and lets
                // it scroll instead of overflowing once the keyboard shrinks
                // the available height below the form's natural size.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),           
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _isRegisterMode ? 'Create an account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (authController.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        authController.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isRegisterMode ? 'Sign up' : 'Log in',
                      isLoading: authController.isLoading,
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() => _isRegisterMode = !_isRegisterMode);
                      },
                      child: Text(
                        _isRegisterMode
                            ? 'Already have an account? Log in'
                            : "Don't have an account? Sign up",
                      ),
                    ),
                  ],
                ),
              ),  
            );
          },
        ),
      ),
    );
  }
}