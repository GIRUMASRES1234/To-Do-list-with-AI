import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _uidCopied = false;

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);
  static const _amber = Color(0xFFE6A817);
  static const _amberDim = Color(0xFF3D2E08);
  static const _textPri = Color(0xFFF0F6FC);
  static const _textSec = Color(0xFF8B949E);
  static const _error = Color(0xFFF85149);
  static const _errorDim = Color(0xFF3D0D0A);

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
    super.dispose();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  Future<void> _copyUid(String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));
    setState(() => _uidCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _uidCopied = false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border, width: 1),
        ),
        title: const Text(
          "Sign out?",
          style: TextStyle(
            color: _textPri,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "You'll need to sign in again to access your account.",
          style: TextStyle(color: _textSec, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _textSec),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            style: TextButton.styleFrom(foregroundColor: _error),
            child: const Text(
              "Sign out",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "No email found";
    final uid = user?.uid ?? "Unknown";
    final initial = email.isNotEmpty ? email[0].toUpperCase() : "?";

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
          "Profile",
          style: TextStyle(
            color: _textPri,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Background accents ──────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.09), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_amber.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        // ── Avatar ────────────────────────────────────────
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: _amberDim,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _amber.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _amber.withOpacity(0.18),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: _amber,
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          email,
                          style: const TextStyle(
                            color: _textPri,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _amberDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _amber.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "Active account",
                            style: TextStyle(
                              color: _amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Info Card ─────────────────────────────────────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Email row
                              _InfoRow(
                                label: "EMAIL",
                                value: email,
                                icon: Icons.alternate_email_rounded,
                              ),
                              Divider(color: _border, height: 1, thickness: 1),
                              // UID row with copy
                              _InfoRow(
                                label: "USER ID",
                                value: uid,
                                icon: Icons.fingerprint_rounded,
                                truncate: true,
                                trailing: IconButton(
                                  icon: Icon(
                                    _uidCopied
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.copy_outlined,
                                    color: _uidCopied ? _amber : _textSec,
                                    size: 18,
                                  ),
                                  onPressed: () => _copyUid(uid),
                                  tooltip: "Copy UID",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Logout Button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogoutDialog(context),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text(
                              "Sign out",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _errorDim,
                              foregroundColor: _error,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _error.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
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

// ── Info Row Widget ───────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool truncate;
  final Widget? trailing;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.truncate = false,
    this.trailing,
  });

  static const _textPri = Color(0xFFF0F6FC);
  static const _textSec = Color(0xFF8B949E);
  static const _amber = Color(0xFFE6A817);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _amber, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  truncate && value.length > 24
                      ? '${value.substring(0, 10)}…${value.substring(value.length - 6)}'
                      : value,
                  style: const TextStyle(
                    color: _textPri,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
