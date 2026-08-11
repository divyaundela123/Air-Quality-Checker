import '../widgets/screen_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/aqi_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../models/aqi_record.dart';
import '../services/mock_ai_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterStatus = 'All';
  final List<String> _filters = ['All', 'Safe', 'Moderate', 'Warning', 'Hazardous'];

  List<AqiRecord> _filteredRecords(List<AqiRecord> records) {
    if (_filterStatus == 'All') return records;
    return records.where((r) => r.status == _filterStatus).toList();
  }

  Future<void> _confirmDelete(BuildContext context, AqiRecord record) async {
    final s = context.read<LanguageProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteRecord, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(s.deleteRecordBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hazardousRed,
                foregroundColor: Colors.white),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AqiProvider>().deleteRecord(record);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.recordDeleted),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final s = context.read<LanguageProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.clearAllHistory, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(s.clearAllHistoryBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hazardousRed,
                foregroundColor: Colors.white),
            child: Text(s.clearAll),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AqiProvider>().clearAllRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AqiProvider>(
      builder: (context, provider, _) {
        final records = _filteredRecords(provider.records);

        final bool isWeb = MediaQuery.of(context).size.width >= 700;
        final s = context.read<LanguageProvider>().strings;
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: isWeb
              ? null
              : AppBar(
                  title: Text(s.historyTitle),
                  automaticallyImplyLeading: false,
                  actions: [
                    if (provider.records.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined,
                            color: AppTheme.hazardousRed),
                        tooltip: s.clearAll,
                        onPressed: () => _confirmClearAll(context),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
          body: ScreenBackground(
            theme: ScreenTheme.history,
            child: Column(
            children: [
              // Web page header (replaces AppBar on web)
              if (isWeb)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Text(s.historyTitle,
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const SizedBox(width: 10),
                      if (provider.records.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppTheme.primaryBlueLight,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${provider.records.length} ${s.recordsCount}',
                            style: const TextStyle(fontSize: 11,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700)),
                        ),
                      const Spacer(),
                      if (provider.isSyncing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: AppTheme.primaryBlue)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.cloud_sync_rounded,
                              color: AppTheme.primaryBlue, size: 18),
                          tooltip: 'Sync from cloud',
                          onPressed: () => provider.syncFromCloud(),
                        ),
                      if (provider.records.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _confirmClearAll(context),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: AppTheme.hazardousRed, size: 18),
                          label: Text(s.clearAll,
                              style: const TextStyle(color: AppTheme.hazardousRed,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              // Filter chips
              if (provider.records.isNotEmpty)
                _FilterBar(
                  filters: _filters,
                  selected: _filterStatus,
                  onSelected: (f) => setState(() => _filterStatus = f),
                ),

              // Content
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : records.isEmpty
                        ? _EmptyState(
                            hasRecords: provider.records.isNotEmpty,
                            filterStatus: _filterStatus,
                          )
                        : _RecordsList(
                            records: records,
                            onDelete: (r) => _confirmDelete(context, r),
                          ),
              ),
            ],
          ),  // Column
          ), // ScreenBackground
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Filter Bar
// ─────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  Color _chipColor(String status) {
    if (status == 'All') return AppTheme.primaryBlue;
    return MockAiService.getStatusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    // Map internal filter key → translated label
    String labelFor(String f) {
      switch (f) {
        case 'All':       return s.all;
        case 'Safe':      return s.safe;
        case 'Moderate':  return s.moderate;
        case 'Warning':   return s.warning;
        case 'Hazardous': return s.hazardous;
        default:          return f;
      }
    }

    return Container(
      color: AppTheme.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = f == selected;
            final chipColor = _chipColor(f);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelected(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labelFor(f),
                    style: TextStyle(
                      color: isSelected ? Colors.white : chipColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Records List
// ─────────────────────────────────────────────
class _RecordsList extends StatelessWidget {
  final List<AqiRecord> records;
  final Function(AqiRecord) onDelete;

  const _RecordsList({required this.records, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _HistoryTile(
          record: record,
          index: index,
          onDelete: () => onDelete(record),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// History Tile
// ─────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final AqiRecord record;
  final int index;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.record,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = MockAiService.getStatusColor(record.status);
    final locale = context.watch<LanguageProvider>().strings.dateLocale;
    final dateStr = DateFormat('EEE, dd MMM yyyy', locale).format(record.timestamp);
    final timeStr = DateFormat('hh:mm a', locale).format(record.timestamp);

    return GestureDetector(
      onTap: () => _showDetail(context, record, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  MockAiService.getStatusIcon(record.status),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AQI ${record.aqiScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(builder: (ctx) {
                          final sl = ctx.read<LanguageProvider>().strings.statusLabel(record.status);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(sl,
                              style: TextStyle(color: color, fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr · $timeStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniStat(
                            icon: Icons.thermostat,
                            value: '${record.temperature.toStringAsFixed(1)}°C'),
                        const SizedBox(width: 10),
                        _MiniStat(
                            icon: Icons.water_drop,
                            value: '${record.humidity.toStringAsFixed(0)}%'),
                        const SizedBox(width: 10),
                        _MiniStat(
                            icon: Icons.cloud,
                            value: '${record.co2.toStringAsFixed(0)}ppm'),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.textLight, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, AqiRecord record, Color color) {
    final locale = context.read<LanguageProvider>().strings.dateLocale;
    final dateStr = DateFormat('EEEE, dd MMMM yyyy  hh:mm a', locale).format(record.timestamp);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(MockAiService.getStatusIcon(record.status),
                      color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AQI ${record.aqiScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),
                    Builder(builder: (ctx) => Text(
                        ctx.read<LanguageProvider>().strings.statusLabel(record.status),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 15))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(dateStr,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const Divider(height: 28),
            _detailRow('Temperature', '${record.temperature.toStringAsFixed(1)} °C'),
            _detailRow('Humidity', '${record.humidity.toStringAsFixed(1)} %'),
            _detailRow('CO₂', '${record.co2.toStringAsFixed(0)} ppm'),
            _detailRow('VOC', '${record.voc.toStringAsFixed(0)} ppb'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                MockAiService.getRecommendation(record.status),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasRecords;
  final String filterStatus;

  const _EmptyState({required this.hasRecords, required this.filterStatus});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.history,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasRecords
                  ? 'No $filterStatus Records'
                  : 'No History Yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasRecords
                  ? 'No readings with "$filterStatus" status found.'
                  : 'Your air quality readings will appear here after your first analysis.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
