import 'package:flutter/material.dart';
import '../services/firebase_account_service.dart';

/// Firebase's hosted reset page owns verification and the new password.
class PasswordRecoveryDialog extends StatefulWidget {
  final String initialEmail;
  final FirebaseAccountService? service;
  const PasswordRecoveryDialog({
    super.key,
    this.initialEmail = '',
    this.service,
  });
  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _sent = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.service ?? FirebaseAccountService.instance)
          .sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = accountAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reset Firebase password'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Firebase sends a secure reset link. Open it in your browser, set your new password, then return to Tally to sign in. Your Google password is unchanged.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('recovery_email'),
            controller: _email,
            enabled: !_busy && !_sent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Account email or saved username',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'An older local-only vault must be migrated using its local password first. Resetting Firebase cannot change an unmigrated local password or recover unsynced data.',
          ),
          if (_sent)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'If this email has a Firebase password account, a reset link has been sent. Check your inbox and spam folder.',
              ),
            ),
          if (_error != null)
            Text(
              _error!,
              key: const Key('recovery_error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('recovery_submit'),
        onPressed: _busy
            ? null
            : _sent
            ? () => Navigator.pop(context, _email.text.trim())
            : _send,
        child: Text(
          _busy
              ? 'Please wait…'
              : _sent
              ? 'Return to sign in'
              : 'Send reset link',
        ),
      ),
    ],
  );
}
