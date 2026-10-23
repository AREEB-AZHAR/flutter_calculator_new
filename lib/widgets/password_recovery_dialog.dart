import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/password_recovery_service.dart';

class PasswordRecoveryDialog extends StatefulWidget {
  final String initialEmail;
  final PasswordRecoveryService? service;
  const PasswordRecoveryDialog({
    super.key,
    this.initialEmail = '',
    this.service,
  });
  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog> {
  late final PasswordRecoveryService _service =
      widget.service ?? PasswordRecoveryService();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _service.cancel();
    for (final controller in [_email, _code, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() work, {
    bool sendsCode = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
      if (!mounted) return;
      if (sendsCode) {
        setState(() => _sent = true);
      } else {
        Navigator.of(context).pop(_email.text.trim());
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is FirebaseFunctionsException
            ? (error.message ??
                  'Recovery is unavailable. Please try again later.')
            : error.toString().replaceFirst('Bad state: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Recover local vault password'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This changes the local vault password on this device. Your Google account password is unchanged.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('recovery_email'),
            controller: _email,
            enabled: !_busy && !_sent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Registered email'),
          ),
          if (_sent) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'A six-digit code was sent. It expires in 10 minutes and can be used once.',
              ),
            ),
            TextField(
              key: const Key('recovery_code'),
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Email code'),
            ),
            TextField(
              key: const Key('recovery_password'),
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              key: const Key('recovery_confirmation'),
              controller: _confirmation,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            const Text(
              'Use at least 8 characters with uppercase, lowercase, a number and a special character.',
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => _service.begin(_email.text),
                      sendsCode: true,
                    ),
              child: const Text('Resend code'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      _service.cancel();
                      setState(() {
                        _sent = false;
                        _error = null;
                        _code.clear();
                      });
                    },
              child: const Text('Change email'),
            ),
          ],
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
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('recovery_submit'),
        onPressed: _busy
            ? null
            : () => _run(
                _sent
                    ? () => _service.complete(
                        _code.text,
                        _password.text,
                        _confirmation.text,
                      )
                    : () => _service.begin(_email.text),
                sendsCode: !_sent,
              ),
        child: Text(
          _busy ? 'Please wait…' : (_sent ? 'Verify and reset' : 'Send code'),
        ),
      ),
    ],
  );
}
