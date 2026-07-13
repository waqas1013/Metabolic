import 'package:flutter/material.dart';
import 'package:metabolic/database/firebase_helper.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isSignUp) {
        await FirebaseHelper().signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await FirebaseHelper().signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      String message = 'Something went wrong. Please try again.';
      final errorStr = e.toString();
      if (errorStr.contains('user-not-found')) {
        message = 'No account found with this email.';
      } else if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
        message = 'Incorrect password. Please try again.';
      } else if (errorStr.contains('email-already-in-use')) {
        message = 'This email is already registered. Try signing in.';
      } else if (errorStr.contains('weak-password')) {
        message = 'Password is too weak. Use at least 6 characters.';
      } else if (errorStr.contains('invalid-email')) {
        message = 'Please enter a valid email address.';
      } else if (errorStr.contains('network-request-failed')) {
        message = 'No internet connection. Please check your network.';
      } else if (errorStr.contains('too-many-requests')) {
        message = 'Too many attempts. Please wait a moment and try again.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
        _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(color: AppTheme.background),
            ),
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Brand
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: const Text(
                              'METABOLIC',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isSignUp ? 'Create Your Account' : 'Welcome Back',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 20),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Enter your password';
                              }
                              if (_isSignUp && val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (_errorMessage.isNotEmpty) const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Sign In',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Toggle Sign In / Sign Up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account?'
                                    : "Don't have an account?",
                                style: const TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                          _errorMessage = '';
                                        });
                                      },
                                child: Text(
                                  _isSignUp ? 'Sign In' : 'Sign Up',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    ),);
  }
}
