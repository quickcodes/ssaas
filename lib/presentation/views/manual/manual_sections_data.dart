import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/manual_section.dart';

class ManualSectionsData {
  ManualSectionsData._();

  static final List<ManualSection> allSections = [
    // 1. TABLES & FLOOR MATRIX
    ManualSection(
      id: 'tables',
      title: 'Running Tables & Floor Matrix',
      subtitle: 'Opening tables, live session timers, cue assignment & floor view',
      category: 'CORE OPERATIONS',
      icon: Icons.table_restaurant_outlined,
      themeColor: AppColors.brandAccent,
      tags: ['Live Timers', 'Floor Matrix', 'Start Match', 'Stop Session'],
      overview:
          'The Floor Matrix provides a real-time command dashboard of every snooker and pool table in the club. Staff can view live timers, assigned customers, playing cues, and active charges at a glance.',
      keyObjectives: [
        'Monitor available, occupied, and maintenance tables in real time.',
        'Quickly start a match session with customer details and custom rates.',
        'Track live playing duration with second-by-second accuracy.',
        'Directly attach canteen snacks or snooker equipment to running tables.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Select an Available Table',
          description:
              'In the Floor Matrix tab, tap any table marked in green with the status "Available".',
          icon: Icons.touch_app_outlined,
        ),
        ManualStep(
          title: 'Enter Player / Customer Information',
          description:
              'Enter the Customer Name or phone number. Optionally assign dedicated club cues or personal cue sticks.',
          icon: Icons.person_outline,
        ),
        ManualStep(
          title: 'Verify Hourly Rate & Start Session',
          description:
              'Confirm the table\'s default hourly rate or adjust it for a custom discount/surge. Tap "Start Match" to initiate the live session clock.',
          icon: Icons.play_arrow_outlined,
        ),
        ManualStep(
          title: 'Manage Ongoing Table',
          description:
              'While running (highlighted in red), the card displays live duration, current running cost, and ordered items. Tap the card to add food/equipment or stop the session.',
          icon: Icons.timer_outlined,
        ),
      ],
      businessRules: [
        'Only staff members who are currently marked as "Online" can start or stop tables.',
        'A table cannot be started if another session is already marked active on the same table.',
        'The timer calculates elapsed minutes continuously from the exact timestamp of match start.',
        'Floor matrix cards automatically refresh and keep the club operator updated in real-time.',
      ],
      proTips: [
        'Keep customer names accurate to easily locate records in Tables History when settling later.',
        'You can order beverages and cue equipment to a running table at any point during play.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can I change the hourly rate for a specific player?',
          answer:
              'Yes! When starting a table, you can manually override the default hourly rate for that session before confirming.',
        ),
        ManualFaq(
          question: 'What if the app is closed while tables are running?',
          answer:
              'All match start timestamps are securely saved in Firestore Cloud. When you reopen the app on any device, the timer calculates duration from the original start time with zero data loss.',
        ),
      ],
    ),

    // 2. TIME & PRICE CALCULATIONS
    ManualSection(
      id: 'calculations',
      title: 'Time & Price Calculations',
      subtitle: 'Dynamic duration pricing, minimum charges & due waiver rules',
      category: 'PRICING ENGINE',
      icon: Icons.calculate_outlined,
      themeColor: AppColors.info,
      tags: ['Formulas', 'Per-Minute Rate', 'Minimum Charge', 'Due Buffer'],
      overview:
          'The ${Constants.appName} system uses a high-precision, fair-pricing calculation engine that computes table charges based on actual elapsed minutes, configured table rates, minimum billing charges, and storewide due buffers.',
      keyObjectives: [
        'Ensure transparent, minute-by-minute billing for customers.',
        'Enforce minimum table charge thresholds to prevent zero-revenue short sessions.',
        'Combine table rent, canteen items, and equipment fees into a unified invoice.',
        'Apply automated rounding and the ₹5 due buffer waiver.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Duration Conversion',
          description:
              'The system measures the elapsed duration: durationMinutes = (closedAt - startedAt) in minutes.',
          icon: Icons.timelapse_outlined,
        ),
        ManualStep(
          title: 'Per-Minute Rate Application',
          description:
              'Hourly rate is converted to per-minute rate: (RatePerHour / 60.0). Table rental = DurationMinutes * (RatePerHour / 60.0).',
          icon: Icons.functions_outlined,
        ),
        ManualStep(
          title: 'Minimum Charge Verification',
          description:
              'If the calculated table rental is less than the table\'s configured minimum charge (e.g. ₹50), the charge is automatically raised to the minimum charge.',
          icon: Icons.arrow_upward_outlined,
        ),
        ManualStep(
          title: 'Grand Total Aggregation',
          description:
              'Grand Total = Table Rental + Canteen Items Total + Equipment Items Total.',
          icon: Icons.receipt_outlined,
        ),
      ],
      businessRules: [
        'Base Formula: Table Charge = Max(Minimum Charge, (Hourly Rate / 60) * Playing Minutes).',
        'Due Buffer Rule: If the customer pays and the remaining unpaid due is less than ₹${Constants.dueBufferAmount.toStringAsFixed(0)}, the system automatically waives the remaining small change and marks the record as fully "Received".',
        'Company dueBufferAmount can be configured in company settings (defaulting to ₹5.00).',
      ],
      proTips: [
        'The ₹5 buffer saves time at the counter by avoiding arguments over small change (e.g., ₹2 or ₹3 short).',
        'Staff can always see the exact breakdown between Table Rental, Canteen Items, and Accessories in the checkout summary.',
      ],
      faqs: [
        ManualFaq(
          question: 'What happens if a player plays for only 5 minutes?',
          answer:
              'If a table has a configured minimum charge (e.g., ₹50), the customer will be billed ₹50 regardless of the 5-minute calculation.',
        ),
        ManualFaq(
          question: 'Where is the due buffer amount stored?',
          answer:
              'It is stored directly inside the Company entity in Firestore and synchronized automatically upon login or app launch.',
        ),
      ],
    ),

    // 3. TABLE RATES CONFIG
    ManualSection(
      id: 'table_rates_config',
      title: 'Table Rates & Pricing Configuration',
      subtitle: 'Configuring table hourly rates, minimum charges & table types',
      category: 'CONFIGURATION',
      icon: Icons.tune_outlined,
      themeColor: AppColors.brandAccentLight,
      tags: ['Hourly Rates', 'VIP Pricing', 'English Pool', 'Snooker'],
      overview:
          'Club administrators can customize rate schedules for different table models, including Full-Size Snooker, English Pool, Russian Pyramid, and AC/VIP lounge tables.',
      keyObjectives: [
        'Configure default hourly rates for each individual table.',
        'Set minimum rental charges to protect table operating costs.',
        'Support different rates for standard vs premium VIP tables.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Navigate to Table Settings',
          description:
              'Admins can view and adjust table configurations in the Table details or management screens.',
          icon: Icons.settings_outlined,
        ),
        ManualStep(
          title: 'Adjust Hourly Rate',
          description:
              'Input the standard hourly rate (e.g., ₹180/hr or ₹240/hr).',
          icon: Icons.currency_rupee,
        ),
        ManualStep(
          title: 'Set Minimum Table Charge',
          description:
              'Define the floor charge for short visits (e.g., ₹60 minimum for first 15-20 mins).',
          icon: Icons.price_check,
        ),
        ManualStep(
          title: 'Save & Apply',
          description:
              'Changes immediately take effect for all subsequent match sessions on that table.',
          icon: Icons.check_circle_outline,
        ),
      ],
      businessRules: [
        'Table rates can be overridden on-the-fly when initiating a specific match.',
        'Rate changes do not modify already running matches to prevent billing discrepancies.',
        'Dynamic Pricing Engine: If a match crosses between normal hours and scheduled custom rate hours, each time segment is sampled and priced according to the rate active during those exact minutes.',
        'If an on-the-fly custom rate is manually typed when starting the table, that session-level price applies continuously throughout the session.',
      ],
      proTips: [
        'Use higher rates for premium 12ft Strachan cloth tables or private VIP air-conditioned rooms.',
        'Configure Happy Hour schedules (e.g. 12 PM - 4 PM) on weekdays to boost afternoon foot traffic.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can different tables have different hourly rates?',
          answer:
              'Yes. Every table maintains its own independent rate profile, table name, and minimum charge.',
        ),
        ManualFaq(
          question: 'How does the system bill a session that starts in normal hours and ends in peak hours?',
          answer:
              'The calculation engine splits the session into exact minute segments at the boundary. Daytime minutes are charged at normal rate, and evening minutes are charged at the peak rate, summing them into a single fair invoice.',
        ),
      ],
      examples: [
        ManualCalculationExample(
          title: 'USE CASE 1: Crossing Normal Daytime Rate into Evening Peak Custom Rate',
          scenario:
              'Normal Base Rate is ₹120/hr (₹2.00/min). Evening Peak Custom Schedule is 6:00 PM to 11:00 PM @ ₹180/hr (₹3.00/min). A customer plays continuously from 5:15 PM to 7:15 PM (Total Duration = 120 minutes / 2 hours).',
          breakdown: [
            'Segment 1 (Normal Daytime Hours: 5:15 PM to 6:00 PM) = 45 minutes @ ₹120/hr (₹2.00/min) → 45 mins × ₹2.00 = ₹90.00',
            'Segment 2 (Evening Peak Custom Hours: 6:00 PM to 7:15 PM) = 75 minutes @ ₹180/hr (₹3.00/min) → 75 mins × ₹3.00 = ₹225.00',
            'Total Table Rental Charge = ₹90.00 (Segment 1) + ₹225.00 (Segment 2) = ₹315.00',
          ],
          totalResult: '₹315.00',
          explanation:
              'The pricing engine automatically splits the session at the 6:00 PM boundary. The player is not unfairly charged peak rate for their daytime play, and the club does not lose peak revenue for evening play.',
        ),
        ManualCalculationExample(
          title: 'USE CASE 2: Crossing Afternoon Happy Hour Discount into Normal Base Hours',
          scenario:
              'Custom Happy Hour Schedule is 12:00 PM to 4:00 PM @ ₹90/hr (₹1.50/min). Normal Base Rate is ₹150/hr (₹2.50/min). A player starts at 3:30 PM and finishes at 5:00 PM (Total Duration = 90 minutes / 1.5 hours).',
          breakdown: [
            'Segment 1 (Happy Hour Window: 3:30 PM to 4:00 PM) = 30 minutes @ ₹90/hr (₹1.50/min) → 30 mins × ₹1.50 = ₹45.00',
            'Segment 2 (Normal Base Hours: 4:00 PM to 5:00 PM) = 60 minutes @ ₹150/hr (₹2.50/min) → 60 mins × ₹2.50 = ₹150.00',
            'Total Table Rental Charge = ₹45.00 (Happy Hour) + ₹150.00 (Normal Rate) = ₹195.00',
          ],
          totalResult: '₹195.00',
          explanation:
              'When the clock strikes 4:00 PM, the discount window ends automatically. Counter staff do not have to manually pause or restart the session.',
        ),
        ManualCalculationExample(
          title: 'USE CASE 3: Multi-Boundary Triple Rate Window (Normal → Evening Peak → Late Night)',
          scenario:
              'Normal Rate is ₹200/hr (₹3.33/min). Evening Peak Schedule: 7:00 PM – 11:00 PM @ ₹300/hr (₹5.00/min). Late Night Schedule: 11:00 PM – 2:00 AM @ ₹240/hr (₹4.00/min). A marathon match runs from 6:30 PM to 11:30 PM (300 minutes / 5 hours).',
          breakdown: [
            'Segment 1 (Normal Hours: 6:30 PM – 7:00 PM) = 30 mins @ ₹200/hr (₹3.333/min) → 30 mins × ₹3.333 = ₹100.00',
            'Segment 2 (Evening Peak: 7:00 PM – 11:00 PM) = 240 mins (4 hrs) @ ₹300/hr (₹5.00/min) → 240 mins × ₹5.00 = ₹1,200.00',
            'Segment 3 (Late Night: 11:00 PM – 11:30 PM) = 30 mins @ ₹240/hr (₹4.00/min) → 30 mins × ₹4.00 = ₹120.00',
            'Total Combined Table Charge = ₹100.00 + ₹1,200.00 + ₹120.00 = ₹1,420.00',
          ],
          totalResult: '₹1,420.00',
          explanation:
              'The pricing engine seamlessly steps across three rate periods in a single continuous session with mathematical precision.',
        ),
        ManualCalculationExample(
          title: 'USE CASE 4: Short Multi-Rate Session with Minimum Table Charge Threshold',
          scenario:
              'Table Minimum Charge is ₹60.00. Normal Rate: ₹120/hr (₹2.00/min). Custom Peak Rate starts at 6:00 PM @ ₹180/hr (₹3.00/min). A player plays a quick 15-minute frame from 5:50 PM to 6:05 PM.',
          breakdown: [
            'Segment 1 (Normal: 5:50 PM – 6:00 PM) = 10 mins @ ₹120/hr (₹2.00/min) → 10 mins × ₹2.00 = ₹20.00',
            'Segment 2 (Peak: 6:00 PM – 6:05 PM) = 5 mins @ ₹180/hr (₹3.00/min) → 5 mins × ₹3.00 = ₹15.00',
            'Calculated Time Cost = ₹20.00 + ₹15.00 = ₹35.00',
            'Minimum Charge Evaluation = Max(₹35.00 calculated, ₹60.00 minimum charge) → Raised to ₹60.00',
          ],
          totalResult: '₹60.00 (Minimum Charge Applied)',
          explanation:
              'Even though the segmented time calculation crossed boundaries to ₹35.00, the club\'s configured minimum charge threshold of ₹60.00 is enforced, protecting table overhead for quick visits.',
        ),
        ManualCalculationExample(
          title: 'USE CASE 5: On-the-Fly Manual Rate Override vs Scheduled Custom Rates',
          scenario:
              'A table normally has daytime rate ₹180/hr and peak rate ₹240/hr. However, at table start, the operator manually enters an agreed promotional rate of ₹150/hr for tournament players.',
          breakdown: [
            'Operator inputs custom rate: ₹150/hr in the "Start Table" dialog.',
            'Match runs for 90 minutes (1.5 hours) spanning from 5:30 PM to 7:00 PM.',
            'Session Override Applied: 90 mins × (₹150 / 60) = ₹225.00',
          ],
          totalResult: '₹225.00 (Flat Custom Override)',
          explanation:
              'A manual session-level custom override locks the agreed price for that specific player, taking precedence over default hourly schedules.',
        ),
      ],
    ),

    // 4. CHECKOUT & BILLING SETTLEMENT
    ManualSection(
      id: 'billing',
      title: 'Checkout & Billing Settlement',
      subtitle: 'Stopping matches, split payments, cash/online settlement & waiver',
      category: 'FINANCIAL SETTLEMENT',
      icon: Icons.receipt_long_outlined,
      themeColor: AppColors.tableAvailable,
      tags: ['Split Pay', 'Cash + UPI', 'Stop Match', 'Due Settlement'],
      overview:
          'The checkout system provides a frictionless POS interface to finalize table bills. Operators can accept full cash, online payments, partial payments with due tracking, or split payments (Cash + Online) in a single step.',
      keyObjectives: [
        'Provide itemized bill breakdowns showing table duration and ordered items.',
        'Support flexible multi-mode split pay (Cash + UPI / Card).',
        'Record individual payment transactions for precise cash register audits.',
        'Automatically settle remaining dues below ₹5 as Received.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Tap Stop Match on Running Table',
          description:
              'On the live table card, tap "Stop Match". This stops the clock and calculates the final invoice.',
          icon: Icons.stop_circle_outlined,
        ),
        ManualStep(
          title: 'Review Itemized Invoice',
          description:
              'Verify total minutes played, table rental, and all canteen/equipment items charged to the match.',
          icon: Icons.receipt_outlined,
        ),
        ManualStep(
          title: 'Choose Payment Mode',
          description:
              'Select "Full Payment", "Partial Payment", "Full Due", or "Split Pay (Cash + Online)".',
          icon: Icons.payments_outlined,
        ),
        ManualStep(
          title: 'Split Pay Execution (If applicable)',
          description:
              'Enter the cash amount and tap "Fill Rest" for the online portion. Select the online channel (UPI / Card).',
          icon: Icons.call_split_outlined,
        ),
        ManualStep(
          title: 'Complete Checkout',
          description:
              'Tap the primary settlement button. The session is closed and moved to Tables History with complete audit logs.',
          icon: Icons.done_all_outlined,
        ),
      ],
      businessRules: [
        'Split Pay generates 2 separate PaymentTransaction entries: one for Cash and one for Online (UPI/Card).',
        'If remaining due is less than ₹${Constants.dueBufferAmount.toStringAsFixed(0)}, the status is automatically set to "Received" and the due is waived.',
        'Operator details (who closed the table) and timestamp are permanently recorded.',
      ],
      proTips: [
        'Use "Fill Rest" in Split Pay mode to auto-calculate the exact online remainder in 1 tap.',
        'When customer leaves without paying, choose "Full Due" and enter their phone number for later collection.',
      ],
      faqs: [
        ManualFaq(
          question: 'What if customer pays ₹196 on a ₹200 bill?',
          answer:
              'Because the remaining balance (₹4) is less than ₹5, the system automatically waives it and marks the bill as fully Received!',
        ),
        ManualFaq(
          question: 'Can we settle dues later from the History tab?',
          answer:
              'Yes! In Tables History, any match with pending due has a "RECEIVE PAYMENT" button with full Single and Split Pay options.',
        ),
      ],
    ),

    // 5. FOOD & CANTEEN MANAGEMENT
    ManualSection(
      id: 'canteen',
      title: 'Food & Canteen Management',
      subtitle: 'Menu items, live table food orders & inventory tracking',
      category: 'INVENTORY & POS',
      icon: Icons.fastfood_outlined,
      themeColor: AppColors.tableMaintenance,
      tags: ['Beverages', 'Snacks', 'Add to Table', 'Stock Count'],
      overview:
          'The Canteen module enables clubs to sell beverages, snacks, hot meals, and combos directly to players. Items can be billed directly to a running table or sold over the counter.',
      keyObjectives: [
        'Maintain a rich menu with prices, categories, and stock quantities.',
        'Add food and drinks to live running tables with instant invoice updates.',
        'Track stock counts in real time and prevent overselling.',
        'Support on-the-fly custom items for off-menu requests.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Open Canteen Tab',
          description:
              'View all food items categorized by Beverages, Snacks, Meals, etc.',
          icon: Icons.restaurant_menu_outlined,
        ),
        ManualStep(
          title: 'Add New Item / Restock',
          description:
              'Staff/Admins can add new items with selling price, purchase cost, and initial stock count.',
          icon: Icons.add_circle_outline,
        ),
        ManualStep(
          title: 'Order to Running Table',
          description:
              'Select "Add to Table", pick the running table, and choose quantity. The charge is instantly linked to that table session.',
          icon: Icons.table_bar_outlined,
        ),
        ManualStep(
          title: 'Custom Item Addition',
          description:
              'If a customer requests something not on the menu, add a "Custom Item" with custom description and price.',
          icon: Icons.edit_note_outlined,
        ),
      ],
      businessRules: [
        'When an item is added to a table, its stock quantity decrements automatically.',
        'Canteen items appear itemized on the final match invoice and CSV export.',
      ],
      proTips: [
        'Keep popular cold beverages (Red Bull, water bottles, energy drinks) well-stocked as they form a major revenue stream.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can items be removed from a table if ordered by mistake?',
          answer:
              'Yes, while the table is running, you can view the attached items and delete accidental orders before closing.',
        ),
      ],
    ),

    // 6. EQUIPMENT & STOCK
    ManualSection(
      id: 'equipments',
      title: 'Equipment Stock & Maintenance',
      subtitle: 'Cues, chalk, tips, maintenance logs & snooker accessory sales',
      category: 'INVENTORY & POS',
      icon: Icons.inventory_2_outlined,
      themeColor: AppColors.brandAccentLight,
      tags: ['Cue Sticks', 'Chalk', 'Tips', 'Cloth Care', 'Maintenance'],
      overview:
          'Manage club snooker equipment, player cue stick lockers, tip replacement services, chalk sales, and table maintenance schedules (ironing, leveling, cloth re-stretching).',
      keyObjectives: [
        'Track equipment inventory: cues, chalk, master tips, cue cases.',
        'Sell equipment directly to players or bill to their table session.',
        'Log maintenance events such as cue re-tipping or table cloth ironing.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'View Equipment Inventory',
          description:
              'Browse equipment items with current in-stock counts and unit prices.',
          icon: Icons.inventory_outlined,
        ),
        ManualStep(
          title: 'Charge to Running Table',
          description:
              'When a customer buys chalk or pays for cue tip replacement, attach it directly to their active table bill.',
          icon: Icons.add_shopping_cart_outlined,
        ),
        ManualStep(
          title: 'Restock Equipment',
          description:
              'Update stock levels when new cue deliveries or maintenance supplies arrive.',
          icon: Icons.system_update_alt_outlined,
        ),
      ],
      businessRules: [
        'Equipment sales are recorded as distinct line items in match history.',
        'Only users with staff or admin permissions can update stock quantities.',
      ],
      proTips: [
        'Regularly maintain cue tips and table cloths to ensure optimal play quality and customer satisfaction.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can equipment items have custom pricing?',
          answer:
              'Yes, custom equipment charges (such as cue tip fixing service) can be billed with custom amounts.',
        ),
      ],
    ),

    // 7. MATCH HISTORY & DUE SETTLEMENTS
    ManualSection(
      id: 'history',
      title: 'Tables Match History & Due Payments',
      subtitle: 'Past matches, transaction logs, audit trails & due collection',
      category: 'FINANCIAL AUDITS',
      icon: Icons.history_edu_outlined,
      themeColor: AppColors.tableOccupied,
      tags: ['Match Audit', 'Due Collection', 'Split Pay in History', 'Transactions'],
      overview:
          'Tables History maintains a permanent, tamper-proof record of every completed match. Staff can inspect match durations, itemized sales, who opened/closed the table, and collect pending dues.',
      keyObjectives: [
        'Search and filter historical match sessions by customer name, table, or date.',
        'Inspect full itemization: rental charge, canteen items, and payment timestamps.',
        'Collect pending dues using Single Pay or Split Pay (Cash + Online).',
        'Track multiple payment installments per match with detailed audit logs.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Open History Tab',
          description:
              'Access the complete list of closed matches. Match cards show "RECEIVED" (green) or "DUE" (red).',
          icon: Icons.history_outlined,
        ),
        ManualStep(
          title: 'Search & Inspect Details',
          description:
              'Search by player name or table. Tap any card to open the "Match Record Details" popup.',
          icon: Icons.search_outlined,
        ),
        ManualStep(
          title: 'Receive Pending Payment',
          description:
              'On any match with a due balance, tap "RECEIVE PAYMENT" to open the Settle Due Payment Screen.',
          icon: Icons.payments_outlined,
        ),
        ManualStep(
          title: 'Choose Single or Split Pay',
          description:
              'Collect the payment via Single Pay (Cash/UPI/Card) or Split Pay (Cash + Online) with "All Cash" and "Fill Rest" helpers.',
          icon: Icons.call_split_outlined,
        ),
        ManualStep(
          title: 'Auto-Settlement (< ₹5)',
          description:
              'If the remaining due after collection is less than ₹5, the system automatically waives the remainder and sets status to "Received".',
          icon: Icons.check_circle_outlined,
        ),
      ],
      businessRules: [
        'Every due settlement adds a new PaymentTransaction with operator name, method, amount, and timestamp.',
        'All payment transactions are preserved for end-of-day cash register reconciliation.',
      ],
      proTips: [
        'Filter by "Due" to immediately see all players who owe money to the club and follow up.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can a player pay their due in multiple installments?',
          answer:
              'Yes! You can collect partial amounts multiple times. Each installment is logged in the payment transactions list until the balance is cleared.',
        ),
      ],
    ),

    // 8. USER ACCOUNTS & ADMIN PRIVILEGES
    ManualSection(
      id: 'users_admin',
      title: 'User Accounts & Role Permissions',
      subtitle: 'Admin vs Staff roles, operator logins, PIN security & staff list',
      category: 'ADMINISTRATION',
      icon: Icons.manage_accounts_outlined,
      themeColor: AppColors.brandAccent,
      tags: ['Admin Role', 'Staff Role', 'PIN Security', 'Permissions'],
      overview:
          '${Constants.appName} supports multi-user role-based access. Administrators can create accounts for club managers and counter staff, set secure 4-digit PINs, and manage permissions.',
      keyObjectives: [
        'Control access between Admin and Staff roles.',
        'Secure operator logins with unique usernames and PINs.',
        'Enable staff to handle tables while reserving sensitive configurations for Admins.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Open Associated Users (Admin Only)',
          description:
              'In the Users tab, Admins can view all registered club staff members.',
          icon: Icons.people_outline,
        ),
        ManualStep(
          title: 'Add New Staff Member',
          description:
              'Tap "Add User". Enter Full Name, Phone Number, Role (Admin or Staff), and a 4-digit Login PIN.',
          icon: Icons.person_add_outlined,
        ),
        ManualStep(
          title: 'Set Permissions',
          description:
              'Staff can operate tables, canteen, and checkouts. Admins have additional access to user management and reports.',
          icon: Icons.security_outlined,
        ),
      ],
      businessRules: [
        'The Users management tab is strictly visible only to logged-in Admins.',
        'PINs must be numeric and securely hashed or protected.',
      ],
      proTips: [
        'Assign each staff member their own account rather than sharing one, ensuring accountability for floor actions.',
      ],
      faqs: [
        ManualFaq(
          question: 'Can a staff member delete match records?',
          answer:
              'No. Match records and financial transactions are permanent audit records to protect the club against revenue leakage.',
        ),
      ],
    ),

    // 9. ONLINE / OFFLINE STATUS & SHIFT TRACKING
    ManualSection(
      id: 'online_offline',
      title: 'Online / Offline Status & Shift Tracking',
      subtitle: 'Single active operator rule, shift hours & working time logs',
      category: 'STAFF OPERATIONS',
      icon: Icons.badge_outlined,
      themeColor: AppColors.tableAvailable,
      tags: ['Single Active User', 'Shift Tracking', 'Working Hours', 'Audit'],
      overview:
          'To ensure absolute accountability for floor cash and table actions, the system enforces a Single Active User rule. Only the staff member who is currently "Online" can start and stop tables.',
      keyObjectives: [
        'Ensure only one staff member is online at any given time to eliminate cash confusion.',
        'Track operator work shifts with exact check-in (online) and check-out (offline) timestamps.',
        'Audit operator working hours directly in the Users tab.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Check Live Status in App Bar',
          description:
              'The top app bar displays your name and a status pill ("ONLINE" in green or "OFFLINE" in gray).',
          icon: Icons.toggle_on_outlined,
        ),
        ManualStep(
          title: 'Toggle Online Status',
          description:
              'Tap your name tag in the app bar to open the Shift Status dialog. Tap the toggle switch to go Online or Offline.',
          icon: Icons.touch_app_outlined,
        ),
        ManualStep(
          title: 'Single-User Online Enforcement',
          description:
              'You can only go online if no other user is currently online. If another user is online, they must go offline first (or you can switch shift).',
          icon: Icons.lock_clock_outlined,
        ),
        ManualStep(
          title: 'View Shift History',
          description:
              'In the Users tab, tap any staff member to view their complete shift history, total working hours, and individual online/offline intervals.',
          icon: Icons.history_outlined,
        ),
      ],
      businessRules: [
        'Only the user who is currently Online can start, edit, or stop match sessions.',
        'Every time a user toggles Online or Offline, an entry with exact DateTime is stored in their shiftHistory array in Firestore.',
        'Total working hours and shift counts are automatically computed from these timestamps.',
      ],
      proTips: [
        'Always toggle Offline when leaving your shift so the next counter operator can go Online immediately.',
      ],
      faqs: [
        ManualFaq(
          question: 'What happens if another operator is online and not at the club?',
          answer:
              'An Admin can log in or open the User Online Status dialog to toggle the previous operator offline and assign the shift to the active operator.',
        ),
      ],
    ),

    // 10. FINANCIAL AUDITS & CSV REPORTS
    ManualSection(
      id: 'reports',
      title: 'Financial Audits & CSV Reports',
      subtitle: 'Revenue summaries, CSV export, accountant reports & date filters',
      category: 'ANALYTICS & REPORTS',
      icon: Icons.assessment_outlined,
      themeColor: AppColors.brandAccentLight,
      tags: ['CSV Export', 'Revenue Audit', 'Total Received', 'Accountant'],
      overview:
          'Generate comprehensive financial audits and export full match records to CSV spreadsheets for club owners, managers, and tax accountants.',
      keyObjectives: [
        'View live aggregations: Total Matches, Total Received Cash/Online, and Total Due.',
        'Export match records to clean, formatted CSV spreadsheets.',
        'Provide transaction-level transparency for daily club reconciliation.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Open Tables History',
          description:
              'The top summary cards display total matches, total revenue collected, and total pending due.',
          icon: Icons.dashboard_outlined,
        ),
        ManualStep(
          title: 'Tap "Report" / Export Button',
          description:
              'Tap the "Report" button in the upper header of the History view.',
          icon: Icons.file_download_outlined,
        ),
        ManualStep(
          title: 'Generate & Share CSV',
          description:
              'The system generates a detailed CSV containing Match IDs, Table Names, Start/End times, Staff Names, Items Ordered, Paid Amounts, and Payment Methods.',
          icon: Icons.share_outlined,
        ),
      ],
      businessRules: [
        'CSV reports can be opened in Excel, Google Sheets, Apple Numbers, or accounting software.',
        'Figures in the report match Firestore transaction logs with 100% precision.',
      ],
      proTips: [
        'Export reports at the end of every business day for reliable ledger reconciliation.',
      ],
      faqs: [
        ManualFaq(
          question: 'Does the CSV include split pay details?',
          answer:
              'Yes! The CSV report clearly lists payment methods, split payments, and customer due balances.',
        ),
      ],
    ),

    // 11. CLUB MEMBERSHIP & EXPIRY RULES
    ManualSection(
      id: 'membership',
      title: 'Club Membership & Expiry Rules',
      subtitle: 'Subscription expiry monitoring, renewal warnings & license status',
      category: 'SYSTEM & LICENSE',
      icon: Icons.card_membership_outlined,
      themeColor: AppColors.tableAvailable,
      tags: ['Subscription', 'Expiry Date', 'License', 'Renewal Warning'],
      overview:
          'Monitor your club\'s ${Constants.appName} membership status and expiry date directly from the navigation drawer and desktop sidebar to ensure uninterrupted access.',
      keyObjectives: [
        'View the club license expiry date at all times in the navigation drawer.',
        'Receive early renewal warnings (14 days in advance) to prevent downtime.',
        'Understand subscription terms and access continuity.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: 'Open Navigation Drawer / Sidebar',
          description:
              'Look at the bottom card displaying your Club Name and Phone Number.',
          icon: Icons.menu_open_outlined,
        ),
        ManualStep(
          title: 'Check Expiry Badge',
          description:
              'Displays "ACTIVE" (green), "RENEW SOON" (amber, <= 14 days), or "EXPIRED" (red).',
          icon: Icons.verified_outlined,
        ),
        ManualStep(
          title: 'Read Days Remaining Countdown',
          description:
              'Shows exact text: "Valid till dd MMM yyyy" or "Expires in X days (dd MMM yyyy)".',
          icon: Icons.calendar_today_outlined,
        ),
        ManualStep(
          title: 'Contact Support for Renewal',
          description:
              'When renewing, your company expiryDate in Firestore is extended immediately without any app updates required.',
          icon: Icons.support_agent_outlined,
        ),
      ],
      businessRules: [
        'If the subscription expires, the app will prompt for renewal upon next session verification.',
        'All club data (tables, history, canteen inventory) remains 100% safe and intact even if expired.',
      ],
      proTips: [
        'Keep an eye on the amber "RENEW SOON" badge to renew your subscription a few days before expiration.',
      ],
      faqs: [
        ManualFaq(
          question: 'Will our data be lost if our membership expires?',
          answer:
              'No, never! All your tables, match history, user accounts, and inventory remain safely preserved in Firestore Cloud.',
        ),
      ],
    ),

    // 12. SESSION SECURITY & SAFE LOGOUT
    ManualSection(
      id: 'logout_security',
      title: 'Session Security & Safe Logout',
      subtitle: '10-day persistent sessions, secure logout & account switching',
      category: 'SECURITY',
      icon: Icons.security_outlined,
      themeColor: AppColors.brandAccent,
      tags: ['10-Day Session', 'Auto-Login', 'Safe Logout', 'PIN Guard'],
      overview:
          'Learn how the app maintains secure 10-day operator sessions so counter staff do not need to re-enter PINs on every launch, while protecting against unauthorized access.',
      keyObjectives: [
        'Understand how auto-login and session persistence work.',
        'Safely log out when changing club operators or shared devices.',
        'Protect club financial data against accidental sign-outs.',
      ],
      stepByStepFlow: [
        ManualStep(
          title: '10-Day Local Session Persistence',
          description:
              'When you log in with your Company Code, Phone, and PIN, your session is saved locally for 10 days for instant app startup.',
          icon: Icons.save_outlined,
        ),
        ManualStep(
          title: 'Tap Logout in Header / Sidebar',
          description:
              'Tap the logout icon in the top app bar or the sidebar.',
          icon: Icons.logout_outlined,
        ),
        ManualStep(
          title: 'Confirm Logout Dialog',
          description:
              'A security dialog asks for confirmation before clearing local credentials to prevent accidental logouts.',
          icon: Icons.help_outline,
        ),
      ],
      businessRules: [
        'Logging out clears local SharedPreferences credentials and takes you to the Login Screen.',
        'Active running tables continue counting on the cloud even if an operator logs out.',
      ],
      proTips: [
        'Do not share your personal PIN with other staff members; each operator should have their own user account.',
      ],
      faqs: [
        ManualFaq(
          question: 'If I log out, will it stop the running tables?',
          answer:
              'No! Running tables and match timers run in Firestore Cloud independently of local device logins.',
        ),
      ],
    ),
  ];
}
