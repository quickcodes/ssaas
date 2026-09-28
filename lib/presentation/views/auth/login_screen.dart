import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/app_navigation.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/bouncing_tap.dart';
import '../contact_and_pricing/pricing_and_contact_view.dart';
import 'create_company_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyCodeCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _logoAnimCtrl;
  late final Animation<double> _logoScaleAnim;

  @override
  void initState() {
    super.initState();
    _logoAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _logoScaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _logoAnimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _logoAnimCtrl.dispose();
    _companyCodeCtrl.dispose();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.medium();

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
    final isMobile = Responsive.isMobile(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showErrorDialog(
            context,
            state.errorMessage!,
            state.isSubscriptionExpired,
            isUserDeactivated: state.isUserDeactivated,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Stack(
            children: [
              // Ambient glow accents
              Positioned(
                top: -80,
                left: -80,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brandAccent.withAlpha(35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0F9D58).withAlpha(30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 18 : 24,
                    vertical: 32,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: EdgeInsets.all(isMobile ? 22 : 36),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorderStroke),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
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
                          // Header Logo with breathing pulse
                          Center(
                            child: ScaleTransition(
                              scale: _logoScaleAnim,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandAccent.withAlpha(
                                        60,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.asset(
                                    "assets/logo.png",
                                    height: isMobile ? 64 : 72,
                                    width: isMobile ? 64 : 72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            Constants.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          const SizedBox(height: 28),

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
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Please enter your company / club code'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // User Identifier (Email or Phone)
                          TextFormField(
                            controller: _identifierCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email Address or Phone Number *',
                              hintText: 'e.g. admin@club.com or 9009395674',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Enter your email or phone number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password *',
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
                          BouncingTap(
                            onTap: state.isLoading ? null : _submitLogin,
                            child: ElevatedButton(
                              onPressed: state.isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                          ),

                          const SizedBox(height: 20),

                          // New Business & Subscription Pricing Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputSurface.withAlpha(150),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.brandAccent.withAlpha(90),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandAccent.withAlpha(40),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.storefront_outlined,
                                    size: 18,
                                    color: AppColors.brandAccentLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'New Club or Subscription?',
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Plans from ₹489 • Contact ${Constants.contactPerson}',
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                BouncingTap(
                                  onTap: () {
                                    AppHaptics.light();
                                    AppNavigation.pushSmooth(
                                      context,
                                      const PricingAndContactView(),
                                    );
                                  },
                                  child: TextButton(
                                    onPressed: () {
                                      AppHaptics.light();
                                      AppNavigation.pushSmooth(
                                        context,
                                        const PricingAndContactView(),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.brandAccent
                                          .withAlpha(35),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: AppColors.brandAccent
                                              .withAlpha(100),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Plans',
                                      style: TextStyle(
                                        color: AppColors.brandAccentLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dev-only Company Creation Option
                          if (Constants.isAdmin) ...[
                            const SizedBox(height: 24),
                            const Divider(color: AppColors.cardBorderStroke),
                            const SizedBox(height: 16),
                            BouncingTap(
                              onTap: () {
                                AppHaptics.light();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreateCompanyScreen(),
                                  ),
                                );
                              },
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  AppHaptics.light();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateCompanyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_business_outlined),
                                label: const Text(
                                  'Create New Company (Dev Mode)',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandAccentLight,
                                  side: const BorderSide(
                                    color: AppColors.brandAccent,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String message,
    bool isSubscriptionExpired, {
    bool isUserDeactivated = false,
  }) {
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
              isUserDeactivated
                  ? Icons.person_off_rounded
                  : (isSubscriptionExpired
                      ? Icons.error_outline
                      : Icons.warning_amber_rounded),
              color: AppColors.tableOccupied,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUserDeactivated
                    ? 'Account Deactivated'
                    : (isSubscriptionExpired
                        ? 'Subscription Expired'
                        : 'Login Error'),
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 460,
          ),
          child: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          if (isSubscriptionExpired) ...[
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AuthBloc>().add(ClearAuthErrorEvent());
                AppNavigation.pushSmooth(
                  context,
                  const PricingAndContactView(),
                );
              },
              child: const Text(
                'View Plans & Contact',
                style: TextStyle(
                  color: AppColors.brandAccentLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
