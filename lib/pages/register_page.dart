import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../utils/notification_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showSuccess = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      NotificationService.instance
          .showError(context, 'Please fill in all fields!');
      return;
    }

    if (password.length < 6) {
      NotificationService.instance
          .showError(context, 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      NotificationService.instance
          .showError(context, 'Passwords do not match!');
      return;
    }

    // Save user via AuthService
    final error = await AuthService.instance.register(
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (error != null) {
      NotificationService.instance.showError(context, error);
      return;
    }

    // Registration succeeded — show animation
    setState(() {
      showSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      NotificationService.instance
          .showSuccess(context, 'Registration successful!');

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, {
          'username': username,
          'email': email,
          'password': password,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: showSuccess
          ? Center(
              child: Lottie.asset(
                'assets/success.json',
                width: 200,
                repeat: false,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(usernameController, 'Username',
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, 'Email',
                      icon: Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(passwordController, 'Password',
                      isObscure: true, icon: Icons.lock_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                      confirmPasswordController, 'Confirm Password',
                      isObscure: true, icon: Icons.lock_outline),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isObscure = false, IconData? icon}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
