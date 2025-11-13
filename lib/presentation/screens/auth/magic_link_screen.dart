import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:app/presentation/providers/auth_provider.dart';

class MagicLinkScreen extends ConsumerStatefulWidget {
  final String email;

  const MagicLinkScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  bool _linkSent = false;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendMagicLink() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).signInWithMagicLink(
        email: _emailController.text.trim(),
      );
      setState(() {
        _linkSent = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwordless Sign In'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                'Magic Link Sign In',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                'Receive a secure link to sign in without a password.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(48),
              if (!_linkSent) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !isLoading,
                  ),
                ),
                const Gap(24),
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSendMagicLink,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Send Magic Link'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mail_outline, color: Colors.blue[700]),
                          const Gap(8),
                          Text(
                            'Link Sent',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'We sent a magic link to ${_emailController.text}. Click the link in your email to sign in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Text(
                  'Tip: Check your spam folder if you don\'t see the email.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Gap(32),
                OutlinedButton(
                  onPressed: () => setState(() => _linkSent = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Send Again'),
                ),
              ],
              const Gap(24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: const Text('Back to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
