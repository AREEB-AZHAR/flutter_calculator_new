import 'package:flutter/material.dart';
import '../services/cloud_sync_service.dart';
import '../services/state.dart';

enum SyncModalState {
  comparing,
  selection,
  uploading,
  completed,
  failed,
}

enum SyncActionChoice {
  loadSavedData,
  mixData,
  uploadFreshData,
}

/// User-centric Cloud Synchronization Modal.
///
/// Features progressive in-app comparison, 3 clear actionable sync strategies
/// (Load Saved, Mix & Merge, Upload Fresh), plain-language change descriptions,
/// interactive loading states, and completion / failure handling.
class CloudSyncModal extends StatefulWidget {
  final String username;
  final String currency;
  final VaultSummary? initialLocalSummary;
  final VaultSummary? initialCloudSummary;

  const CloudSyncModal({
    super.key,
    required this.username,
    required this.currency,
    this.initialLocalSummary,
    this.initialCloudSummary,
  });

  static Future<void> show(BuildContext context) {
    final user = AppState.currentUser ?? 'User';
    final currency = AppState.currencyNotifier.value;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CloudSyncModal(
        username: user,
        currency: currency,
      ),
    );
  }

  @override
  State<CloudSyncModal> createState() => _CloudSyncModalState();
}

class _CloudSyncModalState extends State<CloudSyncModal> {
  SyncModalState _state = SyncModalState.comparing;
  SyncActionChoice _selectedChoice = SyncActionChoice.mixData;
  VaultSummary? _localSummary;
  VaultSummary? _cloudSummary;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialLocalSummary != null) {
      _localSummary = widget.initialLocalSummary;
      _cloudSummary = widget.initialCloudSummary;
      _state = SyncModalState.selection;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runComparison();
      });
    }
  }

  Future<void> _runComparison() async {
    setState(() {
      _state = SyncModalState.comparing;
      _errorMessage = '';
    });

    try {
      final local = await CloudSyncService.fetchLocalSummary(widget.username);
      final cloud = await CloudSyncService.fetchCloudSummary();

      if (mounted) {
        setState(() {
          _localSummary = local;
          _cloudSummary = cloud;
          _state = SyncModalState.selection;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = SyncModalState.failed;
        });
      }
    }
  }

  Future<void> _executeSync() async {
    setState(() {
      _state = SyncModalState.uploading;
      _errorMessage = '';
    });

    bool success = false;
    try {
      switch (_selectedChoice) {
        case SyncActionChoice.loadSavedData:
          success = await CloudSyncService.restoreFromCloud(widget.username);
          break;
        case SyncActionChoice.mixData:
          success = await CloudSyncService.mixAndUploadData(widget.username);
          break;
        case SyncActionChoice.uploadFreshData:
          success = await CloudSyncService.uploadFreshData(widget.username);
          break;
      }
    } catch (e) {
      success = false;
      _errorMessage = e.toString();
    }

    if (mounted) {
      setState(() {
        if (success) {
          _state = SyncModalState.completed;
        } else {
          _state = SyncModalState.failed;
        }
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return PopScope(
      canPop: _state != SyncModalState.uploading && _state != SyncModalState.comparing,
      child: Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: _buildCurrentStateView(theme, surface, onSurface, primary),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView(
    ThemeData theme,
    Color surface,
    Color onSurface,
    Color primary,
  ) {
    switch (_state) {
      case SyncModalState.comparing:
        return _buildComparingView(onSurface, primary);
      case SyncModalState.selection:
        return _buildSelectionView(theme, onSurface, primary);
      case SyncModalState.uploading:
        return _buildUploadingView(onSurface, primary);
      case SyncModalState.completed:
        return _buildCompletedView(onSurface, primary);
      case SyncModalState.failed:
        return _buildFailedView(onSurface, primary);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 1. Initial Comparing State
  // ────────────────────────────────────────────────────────────────
  Widget _buildComparingView(Color onSurface, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Comparing Cloud & Device Data',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Retrieving your cloud records and checking device data...',
          style: TextStyle(
            fontSize: 13,
            color: onSurface.withValues(alpha: 0.65),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 2. Selection & Data Comparison View
  // ────────────────────────────────────────────────────────────────
  Widget _buildSelectionView(ThemeData theme, Color onSurface, Color primary) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_sync_rounded, color: primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Sync',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      'Choose how you want to synchronize',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Side-by-side / Stacked Data Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildDataCard(
                  title: 'On Device',
                  icon: Icons.phone_android_rounded,
                  count: _localSummary?.transactionCount ?? 0,
                  goals: _localSummary?.goalsCount ?? 0,
                  balance: _localSummary?.totalBalance ?? 0.0,
                  date: _formatDate(_localSummary?.lastModified),
                  badgeColor: Colors.blueAccent,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataCard(
                  title: 'In Cloud',
                  icon: Icons.cloud_done_rounded,
                  count: _cloudSummary?.transactionCount ?? 0,
                  goals: _cloudSummary?.goalsCount ?? 0,
                  balance: _cloudSummary?.totalBalance ?? 0.0,
                  date: _cloudSummary != null
                      ? _formatDate(_cloudSummary!.lastModified)
                      : 'No Cloud Data',
                  badgeColor: Colors.teal,
                  onSurface: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            'Select Sync Action:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),

          // 3 Options
          _buildOptionTile(
            choice: SyncActionChoice.mixData,
            title: 'Mix & Merge Data',
            tag: 'Recommended',
            description:
                'Combines both device and cloud records into a unified ledger. No data is lost.',
            primary: primary,
            onSurface: onSurface,
          ),
          const SizedBox(height: 8),

          _buildOptionTile(
            choice: SyncActionChoice.loadSavedData,
            title: 'Load Saved Data',
            tag: 'Restore Cloud',
            description:
                'Replaces local records on this device with your cloud backup records.',
            primary: primary,
            onSurface: onSurface,
          ),
          const SizedBox(height: 8),

          _buildOptionTile(
            choice: SyncActionChoice.uploadFreshData,
            title: 'Upload Fresh Data',
            tag: 'Overwrite Cloud',
            description:
                'Overwrites cloud backup with current device records as an exact copy.',
            primary: primary,
            onSurface: onSurface,
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _executeSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Proceed with Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required int count,
    required int goals,
    required double balance,
    required String date,
    required Color badgeColor,
    required Color onSurface,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: badgeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.currency}${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count txs • $goals goals',
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              fontSize: 9.5,
              color: onSurface.withValues(alpha: 0.45),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required SyncActionChoice choice,
    required String title,
    required String tag,
    required String description,
    required Color primary,
    required Color onSurface,
  }) {
    final selected = _selectedChoice == choice;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedChoice = choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : onSurface.withValues(alpha: 0.14),
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primary : onSurface.withValues(alpha: 0.35),
                  width: selected ? 6 : 2,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.18)
                              : onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? primary : onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: onSurface.withValues(alpha: 0.65),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 3. Uploading / Mixing Loading State
  // ────────────────────────────────────────────────────────────────
  Widget _buildUploadingView(Color onSurface, Color primary) {
    String message;
    switch (_selectedChoice) {
      case SyncActionChoice.loadSavedData:
        message = 'Restoring records from your cloud vault...';
        break;
      case SyncActionChoice.mixData:
        message = 'Mixing device and cloud records into a unified ledger...';
        break;
      case SyncActionChoice.uploadFreshData:
        message = 'Uploading fresh device records to cloud vault...';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Synchronizing Data',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: onSurface.withValues(alpha: 0.65),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 4. Completed State
  // ────────────────────────────────────────────────────────────────
  Widget _buildCompletedView(Color onSurface, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.greenAccent,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Sync Completed!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your data has been successfully updated and synchronized.',
          style: TextStyle(
            fontSize: 13,
            color: onSurface.withValues(alpha: 0.7),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 5. Failed State
  // ────────────────────────────────────────────────────────────────
  Widget _buildFailedView(Color onSurface, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Failed to upload data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Failed to upload data, please try again.',
          style: TextStyle(
            fontSize: 13,
            color: onSurface.withValues(alpha: 0.7),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _state == SyncModalState.comparing ? _runComparison : _executeSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
