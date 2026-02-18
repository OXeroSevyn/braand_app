import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; // Toggle between Login and Sign Up
  String _role = 'Employee'; // 'Employee' or 'Admin'

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
        title: Text('Reset Password',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a password reset link.',
                style: GoogleFonts.spaceMono(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'user@braandins.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL',
                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
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
                    backgroundColor: error != null ? Colors.red : Colors.green,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Header with Toggles
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, theme, _) => Row(
                          children: [
                            // Seasonal Toggle
                            IconButton(
                              onPressed: theme.toggleSnowfall,
                              tooltip: 'Toggle Seasonal Effects',
                              icon: Icon(
                                theme.isSnowfallEnabled
                                    ? _getSeasonIcon()
                                    : _getSeasonIconOutline(),
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Theme Toggle
                            IconButton(
                              onPressed: theme.toggleTheme,
                              tooltip: 'Toggle Theme',
                              icon: Icon(
                                theme.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Branding
                          _buildBranding(isDark),
                          const SizedBox(height: 40),

                          // Auth Form Card
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Auth Header
                                  Text(
                                    _isLogin ? 'Welcome Back' : 'Get Started',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLogin
                                        ? 'Enter your credentials to access the portal.'
                                        : 'Join the workforce operating system.',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Role Selection Tabs (Sign Up only)
                                  if (!_isLogin) ...[
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          _buildTab(
                                              'Employee', _role == 'Employee'),
                                          _buildTab('Admin', _role == 'Admin'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Error Message
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
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Colors.red, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: GoogleFonts.spaceMono(
                                                  color: Colors.red,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Inputs
                                  if (!_isLogin) ...[
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.badge_outlined,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _deptController,
                                      label: 'Department',
                                      icon: Icons.work_outline,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    isDark: isDark,
                                    isPassword: true,
                                  ),

                                  if (_isLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            color: AppColors.brand,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),

                                  // Actions
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ElevatedButton(
                                          onPressed: auth.isLoading
                                              ? null
                                              : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.brand,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.black))
                                              : Text(
                                                  _isLogin
                                                      ? 'ENTER SYSTEM'
                                                      : 'CREATE ACCOUNT',
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton(
                                          onPressed: auth.isLoading
                                              ? null
                                              : () async {
                                                  final error = await auth
                                                      .signInWithGoogle();
                                                  if (error != null &&
                                                      mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(error),
                                                          backgroundColor:
                                                              Colors.red),
                                                    );
                                                  }
                                                },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.2)
                                                  : Colors.grey
                                                      .withOpacity(0.3),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            backgroundColor: Colors.transparent,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.network(
                                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                                height: 20,
                                                width: 20,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(Icons.g_mobiledata,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _toggleMode,
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: _isLogin
                                                  ? "Don't have an account? "
                                                  : "Already have an account? ",
                                            ),
                                            TextSpan(
                                              text: _isLogin
                                                  ? 'Sign Up'
                                                  : 'Login',
                                              style: TextStyle(
                                                color: AppColors.brand,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1,
            ),
            children: const [
              TextSpan(text: 'BRAANDINS'),
              TextSpan(text: '.', style: TextStyle(color: AppColors.brand)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Happy New Year, 2026',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amber : Colors.orange[800],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🎊', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The workforce operating system for the next generation.',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  IconData _getSeasonIcon() {
    final month = DateTime.now().month;
    if (month == 12 || month == 1 || month == 2) return Icons.ac_unit;
    if (month >= 3 && month <= 5) return Icons.local_florist;
    if (month >= 6 && month <= 8) return Icons.wb_sunny;
    return Icons.eco; // Leaf
  }

  IconData _getSeasonIconOutline() {
    // Return outlined versions if available/desired, or just same icon
    return _getSeasonIcon();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.spaceGrotesk(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                size: 20, color: isDark ? Colors.white54 : Colors.black45),
            hintText: isPassword ? '••••••••' : '',
            hintStyle:
                TextStyle(color: isDark ? Colors.white24 : Colors.black26),
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.brand,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleRoleChange(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                isActive && Theme.of(context).brightness == Brightness.light
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isActive
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey
                      : Colors.grey[600]),
            ),
          ),
        ),
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
