import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';

class PricingAndContactView extends StatelessWidget {
  const PricingAndContactView({super.key});

  static const _plans = [
    _SubscriptionPlan(
      'Monthly',
      '28 days',
      '₹489',
      '489',
      'A flexible plan for getting started.',
    ),
    _SubscriptionPlan(
      'Quarterly',
      '84 days',
      '₹1,389',
      '1389',
      'Our most popular option for active clubs.',
      highlight: 'MOST POPULAR',
    ),
    _SubscriptionPlan(
      'Half-yearly',
      '168 days',
      '₹2,889',
      '2889',
      'Longer uninterrupted access for your club.',
    ),
  ];

  Future<void> _makePhoneCall(BuildContext context) async {
    AppHaptics.medium();
    final callUri = Uri(scheme: 'tel', path: Constants.contactPhone);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        return;
      }
    } catch (_) {
      // Copy the number below when a dialer is unavailable.
    }
    if (context.mounted) {
      await _copy(context, Constants.contactPhone, 'Phone number');
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String message) async {
    AppHaptics.medium();
    final uri = Uri.parse(
      'https://wa.me/91${Constants.contactPhone}?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Copy the contact number below when WhatsApp cannot be opened.
    }
    if (context.mounted) {
      await _copy(context, Constants.contactPhone, 'WhatsApp number');
    }
  }

  Future<void> _launchUpiPayment(
    BuildContext context,
    _SubscriptionPlan plan,
  ) async {
    AppHaptics.medium();
    final upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': Constants.subscriptionUpiId,
        'pn': '${Constants.appName} Subscription',
        'am': plan.upiAmount,
        'cu': 'INR',
        'tn': '${plan.label} subscription',
      },
    );

    try {
      if (await launchUrl(upiUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Copy the UPI ID below when a compatible payment app is unavailable.
    }

    if (context.mounted) {
      await _copy(context, Constants.subscriptionUpiId, 'UPI ID');
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    AppHaptics.success();
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardSurfaceElevated,
          content: Text(
            '$label copied to clipboard.',
            style: const TextStyle(color: AppColors.primaryText),
          ),
        ),
      );
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
              'Subscriptions and support',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openWhatsApp(context, _generalMessage),
              icon: const Icon(Icons.chat_outlined, size: 17),
              label: const Text('WhatsApp'),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.cardBorderStroke),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _intro(),
                const SizedBox(height: 24),
                _plansSection(context),
                const SizedBox(height: 24),
                _paymentInstructions(context),
                const SizedBox(height: 24),
                _contactCard(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.cardBorderStroke),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandAccent.withAlpha(40), AppColors.cardSurface],
      ),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          color: AppColors.brandAccentLight,
          size: 30,
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simple club subscriptions',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Full access to tables, billing, canteen, stock, history, and support.',
                style: TextStyle(
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

  Widget _plansSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Choose a subscription',
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Full club access with no transaction or per-table charges.',
        style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final width = narrow
              ? constraints.maxWidth
              : (constraints.maxWidth - 32) / 3;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _plans
                .map(
                  (plan) =>
                      SizedBox(width: width, child: _planCard(context, plan)),
                )
                .toList(),
          );
        },
      ),
    ],
  );

  Widget _planCard(BuildContext context, _SubscriptionPlan plan) {
    final highlighted = plan.highlight != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.brandAccent
              : AppColors.cardBorderStroke,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.label,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (plan.highlight != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withAlpha(45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.highlight!,
                    style: const TextStyle(
                      color: AppColors.brandAccentLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            plan.duration,
            style: const TextStyle(
              color: AppColors.brandAccentLight,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.price,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.detail,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _launchUpiPayment(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: highlighted
                    ? AppColors.brandAccent
                    : AppColors.inputSurface,
                foregroundColor: AppColors.primaryText,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Pay with UPI',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentInstructions(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.cardSurfaceElevated,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.brandAccent.withAlpha(100)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.brandAccentLight,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'How to activate your subscription',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Online payment is not available in the app yet. Please pay by UPI and send the receipt on WhatsApp for activation.',
          style: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        _step(
          '1',
          'Choose your plan',
          'Select the subscription duration that suits your club.',
        ),
        const SizedBox(height: 12),
        _step('2', 'Pay via UPI', 'Send the plan amount to the UPI ID below.'),
        const SizedBox(height: 10),
        _upiId(context),
        const SizedBox(height: 14),
        _step(
          '3',
          'Share your payment receipt',
          'Attach the payment screenshot or receipt on WhatsApp. We will verify it and activate your plan.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () =>
                  _copy(context, Constants.subscriptionUpiId, 'UPI ID'),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy UPI ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: AppColors.primaryText,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openWhatsApp(context, _receiptMessage),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Share receipt on WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                side: const BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _upiId(BuildContext context) => InkWell(
    onTap: () => _copy(context, Constants.subscriptionUpiId, 'UPI ID'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: const Row(
        children: [
          Icon(Icons.qr_code_2_outlined, color: AppColors.brandAccentLight),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPI ID',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  Constants.subscriptionUpiId,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.copy_outlined, color: AppColors.secondaryText, size: 19),
        ],
      ),
    ),
  );

  Widget _contactCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorderStroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need help before subscribing?',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Contact ${Constants.contactPerson} for plan or onboarding support.',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(context),
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: Text('Call ${Constants.contactPhoneFormatted}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inputSurface,
                foregroundColor: AppColors.primaryText,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openWhatsApp(context, _generalMessage),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Chat on WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                side: const BorderSide(color: AppColors.cardBorderStroke),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _step(String number, String title, String detail) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandAccent.withAlpha(45),
          border: Border.all(color: AppColors.brandAccentLight),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.brandAccentLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 12),
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
            const SizedBox(height: 2),
            Text(
              detail,
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
  );

  static String get _generalMessage =>
      'Hello, I would like to know more about ${Constants.appName} subscriptions for my club.';
  static String get _receiptMessage =>
      'Hello, I have paid for my ${Constants.appName} subscription. I am sharing the payment receipt for verification.';
}

class _SubscriptionPlan {
  final String label;
  final String duration;
  final String price;
  final String upiAmount;
  final String detail;
  final String? highlight;

  const _SubscriptionPlan(
    this.label,
    this.duration,
    this.price,
    this.upiAmount,
    this.detail, {
    this.highlight,
  });
}
