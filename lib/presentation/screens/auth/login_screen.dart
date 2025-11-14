import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/domain/models/auth_state.dart' as auth_state_model;
import 'package:app/presentation/providers/auth_provider.dart';
import 'package:app/shared/widgets/custom_button.dart';
import 'package:app/shared/widgets/custom_text_field.dart';
import 'package:app/shared/widgets/custom_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    ref.listen<auth_state_model.AuthState>(
      authProvider,
      (_, next) {
        if (!mounted) {
          return;
        }

        if (next.status == auth_state_model.AuthStatus.authenticated) {
          context.go('/dashboard');
          return;
        }

        final errorMessage = next.error;
        if (errorMessage != null &&
            errorMessage.isNotEmpty &&
            next.status != auth_state_model.AuthStatus.loading) {
          CustomToast.show(
            context,
            message: errorMessage,
            type: ToastType.error,
          );
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == auth_state_model.AuthStatus.loading;
    final errorMessage = authState.error;
    final shouldShowInlineError = errorMessage != null &&
        errorMessage.isNotEmpty &&
        authState.status != auth_state_model.AuthStatus.loading;

    void clearInlineError() {
      if (errorMessage != null && errorMessage.isNotEmpty) {
        ref.read(authProvider.notifier).clearError();
      }
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your email and password to continue.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'admin@ezbillify.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        validator: _validateEmail,
                        onChanged: (_) => clearInlineError(),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        obscureText: _isPasswordObscured,
                        onToggleObscureText: _togglePasswordVisibility,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _handleSignIn(),
                        onChanged: (_) => clearInlineError(),
                      ),
                      const SizedBox(height: 24),
                      if (shouldShowInlineError) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            errorMessage!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomButton(
                        label: 'Sign In',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSignIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
