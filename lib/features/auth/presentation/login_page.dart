import 'package:flutter/material.dart';
import '../data/auth_api.dart';
import 'register_page.dart';
import 'widgets/feature_carousel.dart';
import '../../home/presentation/home_screen.dart';
import '../../../core/storage/auth_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onLoginSuccess, this.onLogout});

  final VoidCallback? onLoginSuccess;
  final VoidCallback? onLogout;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApi();

  bool _loading = false;
  bool _obscurePassword = true;
  final Set<String> _flashFields = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$").hasMatch(value);
  }

  bool _validateAndFlash() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final missing = <String>[];
    if (email.isEmpty) missing.add('email');
    if (password.isEmpty) missing.add('password');

    if (missing.isNotEmpty) {
      setState(() {
        _flashFields
          ..clear()
          ..addAll(missing);
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _flashFields.clear());
        }
      });
      _showError('Please fill all the fields');
      return false;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _flashFields
          ..clear()
          ..add('email');
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _flashFields.clear());
      });
      _showError('Please enter a valid email address');
      return false;
    }

    return true;
  }

  Future<void> _login() async {
    if (!_validateAndFlash()) return;
    setState(() => _loading = true);

    try {
      final response = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final data = response.data;
      final bool isError = data['error'] == true;
      final String message = (data['message'] ?? 'Login failed').toString();

      if (!isError) {
        final user = data['data'];

        debugPrint('Login success: $user');

        // Save user data for persistence
        await AuthStorage.saveUserData(user);

        // Navigate to map home screen
        if (mounted) {
          widget.onLoginSuccess?.call();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                onLogout: widget.onLogout,
                onLoginSuccess: widget.onLoginSuccess,
              ),
            ),
          );
        }
      } else {
        _showError(message);
      }
    } catch (_) {
      _showError('Login failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Logo-like heading: CREW over RIDE with subtle border
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CREW',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'RIDE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Auto-scrolling feature highlights
                const FeatureCarousel(),
                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('email')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('email')
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('password')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('password')
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider line
                        Divider(color: Colors.grey.shade200, height: 24),
                        const SizedBox(height: 8),

                        // Login Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password Link
                        TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: const Text('Forgot Password?'),
                        ),
                        const SizedBox(height: 4),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
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
