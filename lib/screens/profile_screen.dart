import '../widgets/screen_background.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/aqi_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart' as ns;
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
    );
  }

  // ── Profile image helpers ────────────────────────────────────
  Widget _buildAvatar(AuthProvider auth, String initials) {
    final path = auth.profileImagePath;
    if (path.isNotEmpty && !kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover,
            width: 100, height: 100);
      }
    }
    return Container(
      width: 100, height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(color: Colors.white,
                fontSize: 36, fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext ctx, AuthProvider auth) {
    if (kIsWeb) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Photo upload is supported on mobile only.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Choose Photo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: AppTheme.primaryBlueLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.primaryBlue),
                ),
                title: const Text('Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, auth);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF388E3C)),
                ),
                title: const Text('Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, auth);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AuthProvider auth) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 600);
      if (picked == null) return;
      await auth.updateFullProfile(
        name : auth.currentUserName,
        phone: auth.currentUserPhone,
        imagePath: picked.path,
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _SettingsScreen()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.read<LanguageProvider>().strings.logOutQuestion,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(context.read<LanguageProvider>().strings.logOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.read<LanguageProvider>().strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.hazardousRed,
              foregroundColor: Colors.white,
            ),
            child: Text(context.read<LanguageProvider>().strings.logOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AqiProvider>(
      builder: (context, auth, aqiProvider, _) {
        final s = context.watch<LanguageProvider>().strings;
        final initials = auth.currentUserName.isNotEmpty
            ? auth.currentUserName
                .split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0] : '')
                .join()
                .toUpperCase()
            : 'U';

        final bool isWeb = MediaQuery.of(context).size.width >= 700;
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: isWeb
              ? null
              : AppBar(
                  title: Text(s.profile),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _navigateToSettings(context),
                    ),
                  ],
                ),
          body: ScreenBackground(
            theme: ScreenTheme.profile,
            child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Profile Header ─────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.08),
                        AppTheme.accentBlue.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Column(
                    children: [
                      // Profile image with picker
                      GestureDetector(
                        onTap: () => _showImagePickerOptions(context, auth),
                        child: Stack(
                          children: [
                            // Avatar circle
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildAvatar(auth, initials),
                              ),
                            ),
                            // Camera icon badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        auth.currentUserName.isNotEmpty ? auth.currentUserName : 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Email chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 13, color: AppTheme.primaryBlue),
                            const SizedBox(width: 5),
                            Text(
                              auth.currentUserEmail.isNotEmpty
                                  ? auth.currentUserEmail : 'No email',
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Phone number (show only if set)
                      if (auth.currentUserPhone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 13, color: Color(0xFF388E3C)),
                              const SizedBox(width: 5),
                              Text(
                                auth.currentUserPhone,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _navigateToEditProfile(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.textLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 13, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(s.addPhoneNumber,
                                    style: const TextStyle(fontSize: 12,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ProfileStat(
                            label: s.readings,
                            value: '${aqiProvider.records.length}',
                            icon: Icons.bar_chart_rounded,
                            color: AppTheme.primaryBlue,
                          ),
                          Container(height: 36, width: 1,
                              color: AppTheme.textLight),
                          _ProfileStat(
                            label: s.avgAqi,
                            value: aqiProvider.records.isNotEmpty
                                ? aqiProvider.weeklyAvgAqi.toStringAsFixed(1) : '–',
                            icon: Icons.analytics_outlined,
                            color: AppTheme.moderateYellow,
                          ),
                          Container(height: 36, width: 1,
                              color: AppTheme.textLight),
                          _ProfileStat(
                            label: s.statusLabel2,
                            value: aqiProvider.latestRecord != null
                                ? s.statusLabel(aqiProvider.latestStatus) : '–',
                            icon: Icons.shield_outlined,
                            color: AppTheme.safeGreen,
                          ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Account Section
                _SectionHeader(title: s.account),
                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  label: s.personalInfo,
                  onTap: () => _navigateToEditProfile(context),
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  label: s.notifications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const _NotificationSettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Support Section
                _SectionHeader(title: s.support),
                _ProfileMenuItem(
                  icon: Icons.shield_outlined,
                  label: s.privacySecurity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _PrivacySecurityScreen()),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline,
                  label: s.helpCenter,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _HelpCenterScreen()),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  onTap: () => _navigateToSettings(context),
                ),
                const SizedBox(height: 16),

                // Logout
                Material(
                  color: AppTheme.cardBg,
                  child: _ProfileMenuItem(
                    icon: Icons.logout,
                    label: s.logOut,
                    iconColor: AppTheme.hazardousRed,
                    textColor: AppTheme.hazardousRed,
                    onTap: () => _logout(context),
                    showChevron: false,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),  // SingleChildScrollView
          ), // ScreenBackground
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Edit Profile Screen
// ─────────────────────────────────────────────
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _nameController;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController  = TextEditingController(text: auth.currentUserName);
    _emailController.text  = auth.currentUserEmail;
    _phoneController.text  = auth.currentUserPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await context.read<AuthProvider>().updateFullProfile(
          name : _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(s.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel(s.fullName),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'John Doe'),
            ),
            const SizedBox(height: 20),
            _buildLabel(s.email),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'hello@example.com',
                filled: true,
                fillColor: AppTheme.textLight.withValues(alpha: 0.1),
                suffixIcon: const Icon(Icons.lock_outline,
                    size: 18, color: AppTheme.textLight),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel(s.phone),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+1 234 567 8900'),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(s.saveChanges),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  s.cancelText,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────
class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  String _tempUnit = 'Celsius';

  void _showLanguagePicker(BuildContext ctx, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(langProvider.strings.selectLanguage,
                  style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: AppStrings.all.map((lang) {
                final isSelected = lang == langProvider.currentLanguage;
                return InkWell(
                  onTap: () { langProvider.setLanguage(lang); Navigator.pop(ctx); },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlueLight : AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flagEmoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary)),
                              if (lang != AppLanguage.english)
                                Text(_nativeSample(lang),
                                    style: TextStyle(fontSize: 12,
                                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.primaryBlue, size: 22),
                      ],
                    ),
                  ),
                );
              }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nativeSample(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.telugu:  return 'గాలి నాణ్యత పర్యవేక్షణ';
      case AppLanguage.hindi:   return 'वायु गुणवत्ता निगरानी';
      case AppLanguage.tamil:   return 'காற்று தர கண்காணிப்பு';
      case AppLanguage.english: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final langProvider  = context.watch<LanguageProvider>();
    final s             = langProvider.strings;
    final theme         = Theme.of(context);
    final bool isDark   = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.settingsTitle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _SectionHeader(title: s.preferences),
            // Temperature Unit
            Material(
              color: theme.cardColor,
              child: ListTile(
                leading: Icon(Icons.thermostat_outlined,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary),
                title: Text(s.temperatureUnit,
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textPrimary)),
                subtitle: Text(_tempUnit,
                    style: TextStyle(color: isDark ? Colors.white60 : AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                onTap: () {
                  setState(() {
                    _tempUnit = _tempUnit == 'Celsius' ? 'Fahrenheit' : 'Celsius';
                  });
                },
              ),
            ),
            const Divider(height: 1, indent: 56),
            // Dark Mode
            Material(
              color: theme.cardColor,
              child: SwitchListTile(
                secondary: Icon(Icons.dark_mode_outlined,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary),
                title: Text(s.darkMode,
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textPrimary)),
                value: themeProvider.isDarkMode,
                activeThumbColor: AppTheme.primaryBlue,
                onChanged: (v) { themeProvider.toggleTheme(v); },
              ),
            ),
            const Divider(height: 1, indent: 56),
            // Language picker
            Material(
              color: theme.cardColor,
              child: ListTile(
                leading: Icon(Icons.language_outlined,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary),
                title: Text(s.languageLabel,
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary)),
                subtitle: Text(langProvider.currentLanguage.displayName,
                    style: TextStyle(
                        color: isDark ? Colors.white60 : AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                onTap: () => _showLanguagePicker(context, langProvider),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: s.data),
            Material(
              color: theme.cardColor,
              child: ListTile(
                leading: Icon(Icons.download_outlined,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary),
                title: Text(s.exportData,
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data export coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Profile Widgets
// ─────────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final bool showChevron;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppTheme.textSecondary,
    this.textColor = AppTheme.textPrimary,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F4), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Privacy & Security Screen
// ─────────────────────────────────────────────
class _PrivacySecurityScreen extends StatelessWidget {
  const _PrivacySecurityScreen();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(s.privacyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 20),
            Text(
              s.yourPrivacyMatters,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.privacyBody,
              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildPolicySection(s.localStorageTitle, s.localStorageBody),
            const SizedBox(height: 24),
            _buildPolicySection(s.authenticationTitle, s.authenticationBody),
            const SizedBox(height: 24),
            _buildPolicySection(s.sensorPermissionsTitle, s.sensorPermissionsBody),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Help Center Screen
// ─────────────────────────────────────────────
class _HelpCenterScreen extends StatelessWidget {
  const _HelpCenterScreen();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(s.helpCenterTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.help, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 20),
            Text(
              s.howCanWeHelp,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildFaqItem(s.faqWhatIsAqi, s.faqWhatIsAqiAnswer),
            const SizedBox(height: 16),
            _buildFaqItem(s.faqHowCalculated, s.faqHowCalculatedAnswer),
            const SizedBox(height: 16),
            _buildFaqItem(s.faqWhatStatusMean, s.faqWhatStatusMeanAnswer),
            const SizedBox(height: 16),
            _buildFaqItem(s.faqConnectSensor, s.faqConnectSensorAnswer),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notification Settings Screen
// ─────────────────────────────────────────────
class _NotificationSettingsScreen extends StatefulWidget {
  const _NotificationSettingsScreen();
  @override
  State<_NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<_NotificationSettingsScreen> {
  bool _statusChanges  = true;
  bool _dangerAlerts   = true;
  bool _analysisSaved  = true;
  bool _livePolling    = true;

  static const _prefsKey = 'notif_';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _requestBatteryExemption();
  }

  /// Silently asks Android to exempt AeroSense from battery optimisation
  /// so WorkManager background tasks (AQI notifications) always fire.
  Future<void> _requestBatteryExemption() async {
    final alreadyExempt =
        await ns.NotificationService.isIgnoringBatteryOptimizations();
    if (!alreadyExempt) {
      await ns.NotificationService.requestIgnoreBatteryOptimizations();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await _getPrefs();
    setState(() {
      _statusChanges = prefs.getBool('${_prefsKey}status')   ?? true;
      _dangerAlerts  = prefs.getBool('${_prefsKey}danger')   ?? true;
      _analysisSaved = prefs.getBool('${_prefsKey}analysis') ?? true;
      _livePolling   = prefs.getBool('${_prefsKey}live')     ?? true;
    });
  }

  Future<dynamic> _getPrefs() async {
    // Use shared_preferences via provider context
    return await _SharedPrefsHelper.instance;
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await _SharedPrefsHelper.instance;
    await prefs.setBool('$_prefsKey$key', value);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(s.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.realTimeAlerts,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(s.notifyInstantly,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(s.alertTypes,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 12),

          _NotifToggle(
            icon: Icons.swap_vert_circle_outlined,
            color: AppTheme.primaryBlue,
            title: s.statusChanges,
            subtitle: s.statusChangesDesc,
            value: _statusChanges,
            onChanged: (v) { setState(() => _statusChanges = v); _toggle('status', v); },
          ),
          _NotifToggle(
            icon: Icons.warning_amber_rounded,
            color: AppTheme.hazardousRed,
            title: s.dangerAlerts,
            subtitle: s.dangerAlertsDesc,
            value: _dangerAlerts,
            onChanged: (v) { setState(() => _dangerAlerts = v); _toggle('danger', v); },
          ),
          _NotifToggle(
            icon: Icons.save_outlined,
            color: AppTheme.safeGreen,
            title: s.analysisSaved,
            subtitle: s.analysisSavedDesc,
            value: _analysisSaved,
            onChanged: (v) { setState(() => _analysisSaved = v); _toggle('analysis', v); },
          ),
          _NotifToggle(
            icon: Icons.sensors_rounded,
            color: const Color(0xFF9575CD),
            title: s.liveSensorUpdates,
            subtitle: s.liveSensorUpdatesDesc,
            value: _livePolling,
            onChanged: (v) { setState(() => _livePolling = v); _toggle('live', v); },
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.notifications_rounded, color: AppTheme.primaryBlue),
              label: Text(s.sendTestNotification,
                  style: const TextStyle(color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(s.notifFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    // Import here to avoid circular imports
    final service = _NotifServiceHelper();
    await service.showTest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Test notification sent!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Reusable toggle row ───────────────────────────────────────
class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11,
                    color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

// ── Thin helpers to avoid circular logic ─────────────────────

class _SharedPrefsHelper {
  static Future<SharedPreferences> get instance =>
      SharedPreferences.getInstance();
}

class _NotifServiceHelper {
  Future<void> showTest() =>
      ns.NotificationService.showAnalysisSaved(
          status: 'Moderate', aqi: 87.5);
}
