import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Company controllers
  final _companyNameCtrl = TextEditingController();
  final _companyCodeCtrl = TextEditingController();
  final _companyNumberCtrl = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  // Initial Admin User controllers
  final _userNameCtrl = TextEditingController();
  final _userNumberCtrl = TextEditingController();
  final _userEmailCtrl = TextEditingController();
  final _userPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyCodeCtrl.dispose();
    _companyNumberCtrl.dispose();
    _userNameCtrl.dispose();
    _userNumberCtrl.dispose();
    _userEmailCtrl.dispose();
    _userPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    AppHaptics.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandAccent,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    if (_isSubmitting) return;
    if (context.read<AuthBloc>().state.isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    _isSubmitting = true;
    AppHaptics.medium();

    context.read<AuthBloc>().add(
          CreateCompanyWithAdminEvent(
            name: _companyNameCtrl.text.trim(),
            code: _companyCodeCtrl.text.trim().toUpperCase(),
            number: _companyNumberCtrl.text.trim(),
            expiryDate: _expiryDate,
            initialUserName: _userNameCtrl.text.trim(),
            initialUserNumber: _userNumberCtrl.text.trim(),
            initialUserEmail: _userEmailCtrl.text.trim(),
            initialUserPassword: _userPasswordCtrl.text,
          ),
        );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isSubmitting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.tableOccupied,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.tableAvailable,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBase,
        appBar: AppBar(
          backgroundColor: AppColors.cardSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              AppHaptics.light();
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Developer: Create New Company',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 24,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorderStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandAccent.withAlpha(100),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFFFB300),
                            size: 26,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dev Mode: Each company created requires an initial club owner user with full access. General users cannot access this screen.',
                              style: TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Company Profile
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '1. COMPANY PROFILE',
                            style: TextStyle(
                              color: AppColors.brandAccentLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _companyNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Company / Club Name *',
                              hintText: 'e.g. CCD Snooker Club, Matrix Snooker Club',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Company name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _companyCodeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Unique Company Code *',
                              hintText: 'e.g. CCD01, MATRIX, SNOOKER101',
                              prefixIcon: Icon(Icons.pin_outlined),
                              helperText:
                                  'Short unique ID used by staff & admins to login',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Unique company code is required';
                              }
                              final clean = val.trim().toUpperCase();
                              if (clean.length < 3) {
                                return 'Code must be at least 3 characters long';
                              }
                              if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(clean)) {
                                return 'Only letters, numbers, hyphens, and underscores allowed';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _companyNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Company Phone / Contact Number *',
                              hintText: 'e.g. +91 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Company phone number is required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Expiry Date Field
                          BouncingTap(
                            onTap: _pickExpiryDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorderStroke),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.brandAccentLight,
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Subscription Expiry Date *',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd MMMM yyyy').format(_expiryDate),
                                        style: const TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.edit_calendar,
                                    color: AppColors.secondaryText,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Initial Admin User
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '2. INITIAL CLUB OWNER',
                            style: TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'This user will be marked as Club Owner automatically with full control (configuring tables, managing canteen & stock, adding users, and deactivating accounts).',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _userNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner Full Name *',
                              hintText: 'e.g. John Doe',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Owner name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _userNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner Phone Number *',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: Icon(Icons.phone_android_outlined),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Phone number is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _userEmailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner Email *',
                              hintText: 'owner@club.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _userPasswordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Owner Password *',
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
                            validator: (val) => val == null || val.length < 4
                                ? 'Password must be at least 4 characters'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return BouncingTap(
                          onTap: state.isLoading ? null : _submit,
                          child: ElevatedButton(
                            onPressed: state.isLoading ? null : _submit,
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
                                    'CREATE COMPANY & OWNER',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
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

