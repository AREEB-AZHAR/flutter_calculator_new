import 'package:flutter/material.dart';
import '../services/cloud_sync_service.dart';

/// User decision options when resolving a sync conflict between Cloud & Local records.
enum SyncConflictChoice {
  restoreCloud,
  overwriteCloud,
  offlineOnly,
}

/// Side-by-side comparison modal displaying Cloud data vs. Local data
/// and asking the user how to reconcile diverging records.
class SyncConflictDialog extends StatelessWidget {
  final VaultSummary cloudSummary;
  final VaultSummary localSummary;
  final String currency;

  const SyncConflictDialog({
    super.key,
    required this.cloudSummary,
    required this.localSummary,
    required this.currency,
  });

  static Future<SyncConflictChoice?> show(
    BuildContext context, {
    required VaultSummary cloudSummary,
    required VaultSummary localSummary,
    required String currency,
  }) {
    return showDialog<SyncConflictChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SyncConflictDialog(
        cloudSummary: cloudSummary,
        localSummary: localSummary,
        currency: currency,
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync_problem_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Sync Conflict Detected',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Existing Google Cloud records and local device records differ. Compare both and choose how you want to synchronize:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comparison Cards (Side-by-Side or Stacked)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    final cloudCard = _buildSummaryCard(
                      context,
                      title: 'Google Cloud Vault',
                      icon: Icons.cloud_outlined,
                      accentColor: Colors.blueAccent,
                      summary: cloudSummary,
                      actionLabel: 'Restore Cloud Data',
                      actionSub: 'Replaces device data with cloud copy',
                      onSelect: () => Navigator.of(context).pop(SyncConflictChoice.restoreCloud),
                      isRecommended: false,
                    );

                    final localCard = _buildSummaryCard(
                      context,
                      title: 'On-Device Storage',
                      icon: Icons.phone_android_rounded,
                      accentColor: colorScheme.primary,
                      summary: localSummary,
                      actionLabel: 'Upload Device Data',
                      actionSub: 'Overwrites cloud vault with device data',
                      onSelect: () => Navigator.of(context).pop(SyncConflictChoice.overwriteCloud),
                      isRecommended: true,
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          cloudCard,
                          const SizedBox(height: 14),
                          localCard,
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cloudCard),
                          const SizedBox(width: 14),
                          Expanded(child: localCard),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Option 3: Continue Offline Only
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(SyncConflictChoice.offlineOnly),
                  icon: const Icon(Icons.cloud_off_rounded, size: 18),
                  label: const Text('Keep Using Offline Only'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Data Loss Caution Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ Offline-Only Notice: Data will remain strictly on this device. If you uninstall the app or clear device storage, data cannot be recovered.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                            height: 1.3,
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
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required VaultSummary summary,
    required String actionLabel,
    required String actionSub,
    required VoidCallback onSelect,
    required bool isRecommended,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Total Balance
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$currency${summary.totalBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: summary.totalBalance >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(height: 8),

          // Counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions:',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              ),
              Text(
                '${summary.transactionCount}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Goals:',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              ),
              Text(
                '${summary.goalsCount}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Synced:',
                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
              ),
              Text(
                _formatDate(summary.lastModified),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              actionSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
