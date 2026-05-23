import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String errorMessage = "";

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);
  static const _amber = Color(0xFFE6A817);
  static const _amberDim = Color(0xFF3D2E08);
  static const _textPri = Color(0xFFF0F6FC);
  static const _textSec = Color(0xFF8B949E);
  static const _error = Color(0xFFF85149);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Login failed";
      });
    } catch (_) {
      setState(() {
        errorMessage = "Something went wrong";
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _textSec,
        fontSize: 13,
        fontFamily: 'monospace',
        letterSpacing: 0.4,
      ),
      prefixIcon: Icon(icon, color: _textSec, size: 18),
      filled: true,
      fillColor: _bg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _amber, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Subtle geometric accent ─────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.12), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.07), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo / Brand ──────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _amberDim,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _amber.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.task_alt_rounded,
                                  color: _amber,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Welcome back",
                                style: TextStyle(
                                  color: _textPri,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Sign in to continue",
                                style: TextStyle(
                                  color: _textSec,
                                  fontSize: 14,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Card ──────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email
                              const Text(
                                "EMAIL",
                                style: TextStyle(
                                  color: _textSec,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 14,
                                ),
                                cursorColor: _amber,
                                decoration: _fieldDecoration(
                                  "you@example.com",
                                  Icons.alternate_email_rounded,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password
                              const Text(
                                "PASSWORD",
                                style: TextStyle(
                                  color: _textSec,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 14,
                                ),
                                cursorColor: _amber,
                                decoration:
                                    _fieldDecoration(
                                      "••••••••",
                                      Icons.lock_outline_rounded,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _textSec,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => obscurePassword =
                                              !obscurePassword,
                                        ),
                                      ),
                                    ),
                              ),

                              // ── Error ────────────────────────────────────
                              if (errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _error.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: _error,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: const TextStyle(
                                            color: _error,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // ── Login button ─────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : loginUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _amber,
                                    disabledBackgroundColor: _amberDim,
                                    foregroundColor: const Color(0xFF0D0D0D),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF0D0D0D),
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Sign in",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Sign up link ──────────────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: _textSec, fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPage(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: _amber,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
