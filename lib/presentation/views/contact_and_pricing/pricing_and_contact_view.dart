import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/bouncing_tap.dart';

class PricingAndContactView extends StatelessWidget {
  const PricingAndContactView({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    AppHaptics.medium();
    final Uri callUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else if (context.mounted) {
        await _copyToClipboard(context, phone, isFallback: true);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, phone, isFallback: true);
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone, String prefilledText) async {
    AppHaptics.medium();
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(prefilledText)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        await _copyToClipboard(context, phone, isFallback: true);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, phone, isFallback: true);
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text, {bool isFallback = false}) async {
    AppHaptics.success();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cardSurfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.tableAvailable, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFallback
                      ? 'Could not open dialer. Phone number ($text) copied to clipboard!'
                      : 'Copied $text to clipboard!',
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing & Contact',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Club subscriptions & business onboarding',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _makePhoneCall(context, Constants.contactPhone),
              icon: const Icon(Icons.phone, size: 16, color: AppColors.brandAccentLight),
              label: const Text(
                'Call Us',
                style: TextStyle(
                  color: AppColors.brandAccentLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brandAccent.withAlpha(25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.brandAccent.withAlpha(80)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorderStroke, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Header
                _buildHeroBanner(context),
                const SizedBox(height: 24),

                // Direct Contact Card
                _buildContactCard(context),
                const SizedBox(height: 32),

                // Pricing Plans Header
                _buildPricingHeader(),
                const SizedBox(height: 18),

                // Pricing Cards
                _buildPricingGrid(context, isMobile),
                const SizedBox(height: 36),

                // Features Included In All Plans
                _buildFeaturesIncludedSection(context),
                const SizedBox(height: 36),

                // 3-Step Onboarding Process
                _buildOnboardingStepsSection(context),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandAccent.withAlpha(35),
            AppColors.cardSurface,
            AppColors.cardSurface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withAlpha(45),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brandAccentLight.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.sports_esports_outlined,
              size: 36,
              color: AppColors.brandAccentLight,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Grow Your Club with ${Constants.appName}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tableAvailable.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.tableAvailable.withAlpha(120),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'INSTANT SETUP',
                        style: TextStyle(
                          color: AppColors.tableAvailable,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete management portal for snooker, billiards, pool tables, canteen POS, multi-tariff pricing, and due collection. Transparent pricing with zero hidden fees.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandAccent.withAlpha(110)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandAccent.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandAccent.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'DS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            Constants.contactPerson,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.tableAvailable,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Available',
                          style: TextStyle(
                            color: AppColors.tableAvailable,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Product Lead • Sales & Technical Onboarding Support',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Constants.contactPhoneFormatted,
                      style: const TextStyle(
                        color: AppColors.brandAccentLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.cardBorderStroke),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              BouncingTap(
                onTap: () => _makePhoneCall(context, Constants.contactPhone),
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(context, Constants.contactPhone),
                  icon: const Icon(Icons.phone_in_talk, size: 18),
                  label: Text('Call ${Constants.contactPhone}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              BouncingTap(
                onTap: () => _openWhatsApp(
                  context,
                  Constants.contactPhone,
                  'Hello Dhruv, I am interested in getting ${Constants.appName} for my snooker / pool club. Please share details!',
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(
                    context,
                    Constants.contactPhone,
                    'Hello Dhruv, I am interested in getting ${Constants.appName} for my snooker / pool club. Please share details!',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat on WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              BouncingTap(
                onTap: () => _copyToClipboard(context, Constants.contactPhone),
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context, Constants.contactPhone),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy Number'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.cardBorderStroke),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildPricingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sell_outlined,
              color: AppColors.brandAccentLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'MEMBERSHIP & LICENSE PLANS',
              style: TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the right duration for your venue',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'All plans unlock full access with unlimited tables, operators, match history, and zero transaction cuts.',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingGrid(BuildContext context, bool isMobile) {
    final plans = [
      _PricingPlanData(
        durationTitle: '28 Days',
        planSubtitle: 'Starter / Monthly Pass',
        cyclesNote: '1 Cycle (28 Days)',
        price: '₹489',
        regularPrice: null,
        savingsText: null,
        mathBreakdown: 'Standard monthly rate',
        dailyCost: '₹17.46 / day',
        isPopular: false,
        isBestValue: false,
        prefilledMsg: 'Hi Dhruv, I want to subscribe to the 28 Days plan (₹489) for my club.',
        perks: [
          'Full SSAAS feature suite',
          'Unlimited Snooker & Pool Tables',
          'Live Table Matrix & Timers',
          'Canteen & Stock POS',
          'Direct Customer Due Tracking',
          'Standard Support',
        ],
      ),
      _PricingPlanData(
        durationTitle: '84 Days',
        planSubtitle: 'Quarterly Club Pass',
        cyclesNote: '3 Cycles (28 × 3 = 84 Days)',
        price: '₹1,389',
        regularPrice: '₹1,467',
        savingsText: 'SAVE ₹78',
        mathBreakdown: '489 × 3 = ₹1,467 → Pay ₹1,389',
        dailyCost: '₹16.53 / day',
        isPopular: true,
        isBestValue: false,
        prefilledMsg: 'Hi Dhruv, I want to subscribe to the 84 Days plan (₹1,389, Save ₹78) for my club.',
        perks: [
          'Full SSAAS feature suite',
          'Save ₹78 compared to monthly',
          'Unlimited Snooker & Pool Tables',
          'Live Table Matrix & Timers',
          'Canteen & Stock POS',
          'Direct Customer Due Tracking',
          'Priority Support & Onboarding',
        ],
      ),
      _PricingPlanData(
        durationTitle: '168 Days',
        planSubtitle: 'Half-Yearly Elite Pass',
        cyclesNote: '6 Cycles (28 × 6 = 168 Days)',
        price: '₹2,889',
        regularPrice: '₹2,934',
        savingsText: 'SAVE ₹45',
        mathBreakdown: '489 × 6 = ₹2,934 → Pay ₹2,889',
        dailyCost: '₹17.20 / day',
        isPopular: false,
        isBestValue: true,
        prefilledMsg: 'Hi Dhruv, I want to subscribe to the 168 Days plan (₹2,889, Save ₹45) for my club.',
        perks: [
          'Full SSAAS feature suite',
          'Save ₹45 upfront discount',
          'Nearly 6 Months uninterrupted',
          'Unlimited Snooker & Pool Tables',
          'Live Table Matrix & Timers',
          'Canteen & Stock POS',
          'VIP Support & Free Updates',
        ],
      ),
    ];

    if (isMobile) {
      return Column(
        children: plans.map((plan) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _buildPlanCard(context, plan),
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plans.map((plan) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildPlanCard(context, plan),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCard(BuildContext context, _PricingPlanData plan) {
    final borderColor = plan.isPopular
        ? AppColors.brandAccent
        : (plan.isBestValue
            ? AppColors.tableAvailable
            : AppColors.cardBorderStroke);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: plan.isPopular || plan.isBestValue ? 1.8 : 1.0,
        ),
        boxShadow: [
          if (plan.isPopular)
            BoxShadow(
              color: AppColors.brandAccent.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          if (plan.isBestValue)
            BoxShadow(
              color: AppColors.tableAvailable.withAlpha(30),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top highlight banner if Popular or Best Value
          if (plan.isPopular || plan.isBestValue)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: plan.isPopular
                    ? AppColors.brandAccent
                    : AppColors.tableAvailable,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                plan.isPopular ? '★ MOST POPULAR' : '★ BEST VALUE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.durationTitle,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.planSubtitle,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (plan.savingsText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tableAvailable.withAlpha(35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.tableAvailable.withAlpha(120),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          plan.savingsText!,
                          style: const TextStyle(
                            color: AppColors.tableAvailable,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.price,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (plan.regularPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        plan.regularPrice!,
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.dailyCost,
                  style: const TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // Math calculation badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorderStroke),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          plan.mathBreakdown,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.cardBorderStroke),
                const SizedBox(height: 16),

                // Included list
                ...plan.perks.map((perk) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.tableAvailable,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perk,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // Action Button
                BouncingTap(
                  onTap: () => _openWhatsApp(context, Constants.contactPhone, plan.prefilledMsg),
                  child: ElevatedButton(
                    onPressed: () => _openWhatsApp(context, Constants.contactPhone, plan.prefilledMsg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular
                          ? AppColors.brandAccent
                          : (plan.isBestValue
                              ? const Color(0xFF0F9D58)
                              : AppColors.inputSurface),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: plan.isPopular || plan.isBestValue
                              ? Colors.transparent
                              : AppColors.cardBorderStroke,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Get ${plan.durationTitle} Plan',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesIncludedSection(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.table_restaurant_outlined,
        title: 'Live Table Matrix',
        description: 'Real-time timers, automatic billing calculations, and instant table status updates.',
      ),
      _FeatureItem(
        icon: Icons.currency_rupee,
        title: 'Multi-Tariff Pricing Engine',
        description: 'Set custom hourly, 30-min, peak hour, and weekend rates tailored to your venue.',
      ),
      _FeatureItem(
        icon: Icons.fastfood_outlined,
        title: 'Canteen & Inventory POS',
        description: 'Transfer food, snacks, and equipment bills directly to running tables with zero hassle.',
      ),
      _FeatureItem(
        icon: Icons.payment_outlined,
        title: 'Split & Due Settlements',
        description: 'Support multi-mode payments (Cash, UPI, Due) with automated customer ledgers.',
      ),
      _FeatureItem(
        icon: Icons.history_edu_outlined,
        title: 'Match History & CSV Audits',
        description: 'Review every finished session, check item breakdowns, and export reports for bookkeeping.',
      ),
      _FeatureItem(
        icon: Icons.devices_outlined,
        title: 'Multi-Device & Offline Tolerant',
        description: 'Works seamlessly on Android, iOS, Web, and Desktop with 10-day offline support.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.tableAvailable, size: 20),
              const SizedBox(width: 8),
              const Text(
                'WHAT\'S INCLUDED IN ALL PLANS',
                style: TextStyle(
                  color: AppColors.tableAvailable,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Everything your club needs to run smoothly',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: features.map((feat) {
                  return SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorderStroke),
                          ),
                          child: Icon(feat.icon, size: 20, color: AppColors.brandAccentLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feat.title,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                feat.description,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStepsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_outlined, color: AppColors.brandAccentLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'FAST 5-MINUTE ONBOARDING',
                style: TextStyle(
                  color: AppColors.brandAccentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ready to start? Follow 3 easy steps',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            stepNumber: '1',
            title: 'Contact Dhruv Soni',
            subtitle: 'Reach out on call or WhatsApp at +91 9009395674 with your club details.',
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            stepNumber: '2',
            title: 'Get Your Club Code & Credentials',
            subtitle: 'We set up your cloud database with your custom tables, menu, and pricing.',
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            stepNumber: '3',
            title: 'Log In & Start Playing',
            subtitle: 'Enter your Unique Club Code on the login screen and start managing sessions immediately.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.brandAccent.withAlpha(45),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandAccentLight),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingPlanData {
  final String durationTitle;
  final String planSubtitle;
  final String cyclesNote;
  final String price;
  final String? regularPrice;
  final String? savingsText;
  final String mathBreakdown;
  final String dailyCost;
  final bool isPopular;
  final bool isBestValue;
  final String prefilledMsg;
  final List<String> perks;

  const _PricingPlanData({
    required this.durationTitle,
    required this.planSubtitle,
    required this.cyclesNote,
    required this.price,
    this.regularPrice,
    this.savingsText,
    required this.mathBreakdown,
    required this.dailyCost,
    required this.isPopular,
    required this.isBestValue,
    required this.prefilledMsg,
    required this.perks,
  });
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
