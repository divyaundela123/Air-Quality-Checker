import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppTheme.hazardousRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 700;
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: isWeb ? _webBody(s) : _mobileBody(s),
    );
  }

  Widget _webBody(AppStrings s) {
    return Row(
      children: [
        // Left branded panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.primaryBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: -60, right: -60,
                  child: _circle(260, Colors.white.withValues(alpha: 0.06))),
                Positioned(bottom: -80, left: -80,
                  child: _circle(300, Colors.white.withValues(alpha: 0.05))),
                Positioned(top: 100, left: -30,
                  child: _circle(150, Colors.white.withValues(alpha: 0.07))),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(Icons.air, color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 24),
                        Text(s.appName,
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.5)),
                        const SizedBox(height: 10),
                        Text(s.tagline,
                            style: const TextStyle(fontSize: 16, color: Colors.white70)),
                        const SizedBox(height: 48),
                        _featureItem(Icons.sensors_outlined, s.liveSensorReadings),
                        const SizedBox(height: 16),
                        _featureItem(Icons.dashboard_outlined, s.dashboard),
                        const SizedBox(height: 16),
                        _featureItem(Icons.notifications_outlined, s.notifications),
                        const SizedBox(height: 16),
                        _featureItem(Icons.bar_chart_outlined, 'Weekly analytics & trends'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right form panel
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back link
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_new,
                                  size: 14, color: AppTheme.primaryBlue),
                              const SizedBox(width: 4),
                              Text(s.backToLogin,
                                  style: const TextStyle(fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(s.createAccount,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text(s.registerSubtitle,
                            style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                        const SizedBox(height: 36),
                        _buildForm(s),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileBody(AppStrings s) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 28),
                Text(s.createAccount,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(s.registerSubtitle,
                    style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                const SizedBox(height: 36),
                _buildForm(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AppStrings s) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(s.fullName),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'John Doe'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '${s.fullName} is required';
              if (v.trim().length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _label(s.email),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'hello@example.com'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '${s.email} is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _label(s.password),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return '${s.password} is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleRegister,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(s.createAccount),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.alreadyHaveAccount,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(s.logIn,
                      style: const TextStyle(color: AppTheme.primaryBlue,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));

  Widget _circle(double size, Color color) => Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _featureItem(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 14),
      Text(text, style: const TextStyle(fontSize: 14, color: Colors.white,
          fontWeight: FontWeight.w500)),
    ],
  );
}
