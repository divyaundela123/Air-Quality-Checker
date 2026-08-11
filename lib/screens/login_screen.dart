import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../services/auth_api_service.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.hazardousRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Forgot Password Dialog ──────────────────────────────────
  void _showForgotPasswordDialog(BuildContext ctx) {
    final emailCtrl   = TextEditingController(text: _emailController.text.trim());
    final newPwdCtrl  = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool isLoading     = false;
    bool obscureNew    = true;
    bool obscureConfirm= true;

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.primaryBlue, size: 22),
            SizedBox(width: 8),
            Text('Reset Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ]),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your email and choose a new password.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  const Text('Email', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'hello@example.com'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('New Password', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: newPwdCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            color: AppTheme.textSecondary, size: 18),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Confirm Password', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            color: AppTheme.textSecondary, size: 18),
                        onPressed: () =>
                            setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != newPwdCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isLoading = true);
                // Capture provider before async gap to avoid BuildContext warning
                final authProvider = context.read<AuthProvider>();
                try {
                  await AuthApiService.resetPassword(
                    email      : emailCtrl.text.trim(),
                    newPassword: newPwdCtrl.text,
                  );
                  // Update local stored password too
                  await authProvider.updateLocalPassword(
                    email      : emailCtrl.text.trim(),
                    newPassword: newPwdCtrl.text,
                  );
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('Password reset! Please log in again.',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    backgroundColor: AppTheme.safeGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (!dialogCtx.mounted) return;
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                    content: Text(ApiService.parseError(e)),
                    backgroundColor: AppTheme.hazardousRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Reset Password',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
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
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(top: -60, left: -60,
                  child: _circle(240, Colors.white.withValues(alpha: 0.06))),
                Positioned(bottom: -80, right: -80,
                  child: _circle(300, Colors.white.withValues(alpha: 0.05))),
                Positioned(top: 120, right: -40,
                  child: _circle(140, Colors.white.withValues(alpha: 0.07))),
                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
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
                        _featureItem(Icons.air_outlined, s.liveSensorReadings),
                        const SizedBox(height: 16),
                        _featureItem(Icons.thermostat_outlined, 'Live Temperature & Humidity'),
                        const SizedBox(height: 16),
                        _featureItem(Icons.cloud_outlined, 'CO₂ & VOC Monitoring'),
                        const SizedBox(height: 16),
                        _featureItem(Icons.history_outlined, 'Historical Trends & Analytics'),
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
                        Text(s.welcomeBack,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text(s.loginSubtitle,
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
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )],
                        ),
                        child: const Icon(Icons.air, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(s.appName,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(s.tagline,
                          style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(s.welcomeBack,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(s.loginSubtitle,
                    style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                const SizedBox(height: 32),
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
            onFieldSubmitted: (_) => _handleLogin(),
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
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: Text(s.forgotPassword,
                  style: const TextStyle(color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(s.logIn),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.noAccount,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(s.signUp,
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
