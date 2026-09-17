import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'create_company_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyCodeCtrl.dispose();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      LoginCompanyUserEvent(
        companyCode: _companyCodeCtrl.text.trim().toUpperCase(),
        emailOrNumber: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showErrorDialog(
            context,
            state.errorMessage!,
            state.isSubscriptionExpired,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorderStroke),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(90),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Title
                      // Center(
                      //   child: Container(
                      //     width: 68,
                      //     height: 68,
                      //     decoration: BoxDecoration(
                      //       gradient: const LinearGradient(
                      //         colors: [AppColors.brandAccent, Color(0xFF0F9D58)],
                      //         begin: Alignment.topLeft,
                      //         end: Alignment.bottomRight,
                      //       ),
                      //       borderRadius: BorderRadius.circular(20),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: AppColors.brandAccent.withAlpha(100),
                      //           blurRadius: 20,
                      //           offset: const Offset(0, 6),
                      //         ),
                      //       ],
                      //     ),
                      //     child: const Icon(
                      //       Icons.sports_esports,
                      //       color: Colors.white,
                      //       size: 34,
                      //     ),
                      //   ),
                      // ),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            "assets/logo.png",
                            height: 68,
                            width: 68,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Snooker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Snooker & Billiards Management Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Company Selector
                      // Company Code
                      const Text(
                        'ENTER YOUR CLUB CODE',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _companyCodeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Unique Company / Club Code *',
                          hintText: 'e.g. CCD01, MATRIX',
                          prefixIcon: Icon(Icons.apartment_outlined),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter your company / club code'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // User Identifier (Email or Phone)
                      TextFormField(
                        controller: _identifierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email Address or Phone Number',
                          hintText: 'e.g. admin@club.com or 9876543210',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter your email or phone number'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.secondaryText,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Enter your password'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // Login Button
                      ElevatedButton(
                        onPressed: state.isLoading ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'LOGIN TO CLUB',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),

                      // Dev-only Company Creation Option
                      if (Constants.isAdmin) ...[
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.cardBorderStroke),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateCompanyScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Create New Company (Dev Mode)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandAccentLight,
                            side: const BorderSide(
                              color: AppColors.brandAccent,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String message,
    bool isSubscriptionExpired,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: Row(
          children: [
            Icon(
              isSubscriptionExpired
                  ? Icons.error_outline
                  : Icons.warning_amber_rounded,
              color: AppColors.tableOccupied,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isSubscriptionExpired ? 'Subscription Expired' : 'Login Error',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(ClearAuthErrorEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
