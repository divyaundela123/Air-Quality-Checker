import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/aqi_provider.dart';
import '../theme/app_theme.dart';

/// Shows a slim banner indicating cloud DB / sync status.
/// Only visible when the user is logged in (inside dashboard).
class DbStatusBanner extends StatelessWidget {
  const DbStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show on web — on mobile the backend runs on a separate PC
    final isWeb = MediaQuery.of(context).size.width >= 700;
    if (!isWeb) return const SizedBox.shrink();

    return Consumer2<AuthProvider, AqiProvider>(
      builder: (context, auth, aqi, _) {
        // ── Never show on login / register screens ──────────────
        if (!auth.isLoggedIn) return const SizedBox.shrink();

        final bool serverUp  = auth.isServerReachable;
        final bool dbUp      = auth.isDbReady;
        final bool syncing   = aqi.isSyncing;
        final String? syncErr= aqi.syncError;

        // All healthy — hide the banner
        if (serverUp && dbUp && !syncing && syncErr == null) {
          return const SizedBox.shrink();
        }

        // Pick message + color
        Color    bg;
        Color    fg;
        IconData icon;
        String   message;
        Widget  trailing = const SizedBox.shrink();

        if (!serverUp) {
          bg      = const Color(0xFFFF5252);
          fg      = Colors.white;
          icon    = Icons.cloud_off_rounded;
          message = 'Backend offline — start the Node.js server (port 3000)';
          trailing = TextButton(
            onPressed: auth.checkServerStatus,
            child: Text('Retry', style: TextStyle(
                color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
          );
        } else if (!dbUp) {
          bg      = const Color(0xFFFF8C42);
          fg      = Colors.white;
          icon    = Icons.storage_rounded;
          message = 'Database not connected — start MySQL / XAMPP';
          trailing = TextButton(
            onPressed: auth.checkServerStatus,
            child: Text('Retry', style: TextStyle(
                color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
          );
        } else if (syncing) {
          bg      = AppTheme.primaryBlueLight;
          fg      = AppTheme.primaryBlue;
          icon    = Icons.sync_rounded;
          message = 'Syncing with cloud database…';
          trailing = const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppTheme.primaryBlue),
          );
        } else if (syncErr != null) {
          bg      = const Color(0xFFFFF3E0);
          fg      = const Color(0xFFE65100);
          icon    = Icons.warning_amber_rounded;
          message = syncErr;
          trailing = IconButton(
            icon: Icon(Icons.refresh_rounded, color: fg, size: 16),
            onPressed: aqi.syncFromCloud,
            tooltip: 'Retry sync',
          );
        } else {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          color: bg,
          child: Row(
            children: [
              Icon(icon, color: fg, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                  style: TextStyle(fontSize: 12, color: fg,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              ),
              trailing,
            ],
          ),
        );
      },
    );
  }
}
