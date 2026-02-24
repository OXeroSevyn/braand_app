import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';

class WebAuthScreen extends StatefulWidget {
  const WebAuthScreen({super.key});

  @override
  State<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends State<WebAuthScreen> {
  bool _isLogin = true;
  String _role = 'Employee';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deptController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  void _handleRoleChange(String newRole) {
    setState(() {
      _role = newRole;
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('Reset Password',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a password reset link.',
                style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'user@braandins.com',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: AppColors.brand),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              Navigator.pop(context);

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final error =
                  await auth.resetPassword(emailController.text.trim());

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? 'Password reset email sent! Check your inbox.',
                      style: GoogleFonts.spaceMono(),
                    ),
                    backgroundColor:
                        error != null ? Colors.red : AppColors.brand,
                  ),
                );
              }
            },
            child: Text('SEND LINK',
                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _error = null);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    String? error;
    if (_isLogin) {
      error = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      if (_nameController.text.isEmpty || _deptController.text.isEmpty) {
        setState(() => _error = 'Please fill all fields');
        return;
      }
      error = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _role,
        department: _deptController.text.trim(),
      );
    }

    if (error != null && mounted) {
      setState(() {
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark mode logic for the auth screen as it looks best
    const isDark = true;

    return Scaffold(
      backgroundColor: Colors.black, // Ensure background is black
      body: Stack(
        children: [
          // Static Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: AppColors.brand.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Stack(
            children: [
              // Theme Toggle (Optional, maybe hide for pure immersive feel, but keeping for utility)
              Positioned(
                top: 40,
                right: 20,
                child: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Row(
                    children: [
                      IconButton(
                        onPressed: theme.toggleSnowfall,
                        icon: Icon(theme.isSnowfallEnabled
                            ? Icons.ac_unit
                            : Icons.ac_unit_outlined),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding
                      _buildBranding(isDark),
                      const SizedBox(height: 48),

                      // Auth Form
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: NeoCard(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isLogin) ...[
                                Row(
                                  children: [
                                    _buildTab('Employee', _role == 'Employee'),
                                    _buildTab('Admin', _role == 'Admin'),
                                  ],
                                ),
                                const SizedBox(height: 32),
                              ],

                              ShaderMask(
                                shaderCallback: (bounds) => AppColors
                                    .brandGradient
                                    .createShader(bounds),
                                child: Text(
                                  _isLogin ? 'WELCOME BACK' : 'JOIN THE FUTURE',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLogin
                                    ? 'Enter your credentials to access the system.'
                                    : 'Create your digital identity.',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              if (_error != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              // Inputs
                              if (!_isLogin) ...[
                                _buildInputLabel('Full Name'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _nameController,
                                  icon: Icons.badge_outlined,
                                  hint: 'John Doe',
                                ),
                                const SizedBox(height: 16),
                                _buildInputLabel('Department'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _deptController,
                                  icon: Icons.work_outline,
                                  hint: 'Engineering',
                                ),
                                const SizedBox(height: 16),
                              ],

                              _buildInputLabel('Email'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                hint: 'user@braandins.com',
                              ),
                              const SizedBox(height: 16),

                              _buildInputLabel('Password'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                hint: '••••••••',
                                isPassword: true,
                              ),

                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),

                              Consumer<AuthProvider>(
                                builder: (context, auth, _) => NeoButton(
                                  text: _isLogin
                                      ? 'ENTER SYSTEM'
                                      : 'CREATE ACCOUNT',
                                  isLoading: auth.isLoading,
                                  onPressed: _handleSubmit,
                                  icon: Icon(
                                    _isLogin
                                        ? Icons.arrow_forward
                                        : Icons.person_add,
                                    color: Colors
                                        .black, // Changed to black for contrast on Neon Green
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Google Sign In Button
                              OutlinedButton(
                                onPressed: () async {
                                  final auth = Provider.of<AuthProvider>(
                                      context,
                                      listen: false);
                                  final error = await auth.signInWithGoogle();
                                  if (error != null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error,
                                          style: GoogleFonts.spaceMono(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                      height: 24,
                                      width: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.g_mobiledata,
                                                  color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CONTINUE WITH GOOGLE',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: _toggleMode,
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isLogin
                                            ? 'New here? '
                                            : 'Already have an account? ',
                                      ),
                                      TextSpan(
                                        text: _isLogin ? 'SIGN UP' : 'LOGIN',
                                        style: TextStyle(
                                          color: AppColors.brandSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.spaceGrotesk(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brand, width: 1),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
                letterSpacing: -1,
              ),
              children: [
                const TextSpan(text: 'BRAANDINS'),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    color: AppColors.brandSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            'Next Gen Workforce OS',
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleRoleChange(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.brandSecondary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.spaceMono(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppColors.brandSecondary,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
