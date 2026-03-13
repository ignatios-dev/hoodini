import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_notifier.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/result/result.dart';

const _mascot = r'''
    ░░░░░░░░░░░░░░░
    ░░▄█████████▄░░
    ░███░░░░░░░███░
    ███  ◉   ◉  ███
    ███    ▲    ███
    ░███  ═══  ███░
    ░░░▀███████▀░░░
    ░░░░╔═════╗░░░░
    ░░░░║ HOO ║░░░░
    ░░▄▄╚═════╝▄▄░░
    ░█▀▀▀▀▀▀▀▀▀▀▀█░
    ░█  D I N I  █░
    ░▀▄▄▄▄▄▄▄▄▄▄▄▀░
    ░░░░░║░░░║░░░░░
    ░░░░░║░░░║░░░░░
    ░░░▄▀▀░░░▀▀▄░░░
''';

const _tagline = '// mark your hood. own the streets. //';

class NicknamePage extends ConsumerStatefulWidget {
  const NicknamePage({super.key});

  @override
  ConsumerState<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends ConsumerState<NicknamePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _showEmail = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref.read(authNotifierProvider.notifier).signIn(
          nickname: _nicknameController.text,
          email: _showEmail ? _emailController.text : null,
        );
    if (mounted && result.isErr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorOrNull ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // ASCII mascot
                    Text(
                      _mascot,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.2,
                        color: cs.primary,
                        letterSpacing: 0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: cs.secondary,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Nickname field
                    TextFormField(
                      controller: _nicknameController,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        labelText: 'YOUR ALIAS',
                        hintText: 'what do they call you?',
                        prefixIcon: Icon(Icons.person_outline, color: cs.primary),
                        prefixText: '> ',
                        prefixStyle: TextStyle(
                          color: cs.primary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction:
                          _showEmail ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: (_) => _showEmail ? null : _submit(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'You need an alias';
                        }
                        if (v.trim().length < AppConstants.minNicknameLength) {
                          return 'At least ${AppConstants.minNicknameLength} chars';
                        }
                        if (v.trim().length > AppConstants.maxNicknameLength) {
                          return 'Max ${AppConstants.maxNicknameLength} chars';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    if (!_showEmail)
                      TextButton.icon(
                        onPressed: () => setState(() => _showEmail = true),
                        icon: Icon(Icons.lock_outline, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                        label: Text(
                          'add email backup (optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),

                    if (_showEmail) ...[
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'EMAIL BACKUP',
                          prefixIcon: Icon(Icons.mail_outline, color: cs.primary),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.contains('@')) return 'invalid email';
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('[ ENTER THE HOOD ]'),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
