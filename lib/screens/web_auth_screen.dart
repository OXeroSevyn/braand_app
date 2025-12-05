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
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
          ),

          // Theme Toggle
          Positioned(
            top: 40,
            right: 20,
            child: Consumer<ThemeProvider>(
              builder: (context, theme, _) => IconButton(
                onPressed: theme.toggleTheme,
                icon:
                    Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.black : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    ),
                  ),
                ),
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
                      padding: const EdgeInsets.all(32),
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

                          Text(
                            _isLogin ? 'PORTAL LOGIN' : 'NEW ACCOUNT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isLogin
                                ? 'Enter your credentials.'
                                : 'Join the workforce.',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // Inputs
                          if (!_isLogin) ...[
                            _buildInputLabel('Full Name'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                                hintText: 'John Doe',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInputLabel('Department'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _deptController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.work_outline),
                                hintText: 'Engineering',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _buildInputLabel('Email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'user@braandins.com',
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInputLabel('Password'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline),
                              hintText: '••••••••',
                            ),
                          ),
                          const SizedBox(height: 32),

                          Consumer<AuthProvider>(
                            builder: (context, auth, _) => NeoButton(
                              text:
                                  _isLogin ? 'ENTER SYSTEM' : 'CREATE ACCOUNT',
                              isLoading: auth.isLoading,
                              onPressed: _handleSubmit,
                              icon: Icon(
                                _isLogin
                                    ? Icons.arrow_forward
                                    : Icons.person_add,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isLogin
                                  ? 'Need an account? SIGN UP'
                                  : 'Already have an account? LOGIN',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.brand : Colors.black,
                                decoration: TextDecoration.underline,
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
                color: isActive ? AppColors.brand : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              color: isActive
                  ? AppColors.brand
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey
                      : Colors.black54),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.brand
            : Colors.black,
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
