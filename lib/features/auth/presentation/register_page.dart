import 'package:flutter/material.dart';
import '../data/auth_api.dart';
import 'widgets/feature_carousel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _authApi = AuthApi();

  bool _loading = false;
  bool _obscurePassword = true;
  final Set<String> _flashFields = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$").hasMatch(value);
  }

  bool _validateAndFlash() {
    final map = {
      'username': _usernameController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    final missing = map.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();

    if (missing.isNotEmpty) {
      setState(() {
        _flashFields
          ..clear()
          ..addAll(missing);
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _flashFields.clear());
      });
      _showError('Please fill all the fields');
      return false;
    }

    if (!_isValidEmail(map['email']!)) {
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

  Future<void> _register() async {
    if (!_validateAndFlash()) return;

    setState(() => _loading = true);
    try {
      final res = await _authApi.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      final data = res.data;
      final bool isError = data['error'] == true;
      final String message = (data['message'] ?? 'Registration completed')
          .toString();

      if (!isError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        _showError(message);
      }
    } catch (_) {
      _showError('Registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  String? _required(String? v, {int? min}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Required';
    if (min != null && value.length < min) return 'Min $min characters';
    return null;
  }

  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Required';
    final ok = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}").hasMatch(value);
    return ok ? null : 'Invalid email';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Auto-scrolling feature highlights
              const FeatureCarousel(),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Join CrewRide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('username')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('username')
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('fullName')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('fullName')
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
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
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('phone')
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _flashFields.contains('phone')
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
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
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
