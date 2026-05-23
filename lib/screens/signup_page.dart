import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String errorMessage = "";

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Palette (matches LoginPage) ───────────────────────────────────────────
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
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signupUser() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() {
        errorMessage = "Passwords do not match.";
        isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Signup failed";
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
  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
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

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: _textSec,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textSec,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back to sign in",
          style: TextStyle(
            color: _textSec,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Background accents ────────────────────────────────────────────
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────────
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
                                  Icons.person_add_alt_1_rounded,
                                  color: _amber,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Create an account",
                                style: TextStyle(
                                  color: _textPri,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Get started — it only takes a moment",
                                style: TextStyle(color: _textSec, fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Card ─────────────────────────────────────────────
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
                              _fieldLabel("EMAIL"),
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
                              _fieldLabel("PASSWORD"),
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

                              const SizedBox(height: 20),

                              // Confirm Password
                              _fieldLabel("CONFIRM PASSWORD"),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirm,
                                style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 14,
                                ),
                                cursorColor: _amber,
                                decoration:
                                    _fieldDecoration(
                                      "••••••••",
                                      Icons.lock_person_outlined,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: _textSec,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () =>
                                              obscureConfirm = !obscureConfirm,
                                        ),
                                      ),
                                    ),
                              ),

                              // ── Error ──────────────────────────────────────
                              if (errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 16),
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

                              // ── Submit button ───────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : signupUser,
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
                                          "Create account",
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

                        // ── Sign in link ──────────────────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(color: _textSec, fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
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
                                  "Sign in",
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
