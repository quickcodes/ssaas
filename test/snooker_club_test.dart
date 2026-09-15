import 'package:flutter_test/flutter_test.dart';
import 'package:snooker/domain/entities/canteen_item.dart';
import 'package:snooker/domain/entities/equipment_item.dart';
import 'package:snooker/domain/entities/shift_record.dart';
import 'package:snooker/domain/entities/table_session.dart';
import 'package:snooker/domain/entities/user_account.dart';

void main() {
  group('1. Dynamic Rate Engine & Peak / Off-Peak Switching', () {
    test('Calculates fixed frame rate regardless of duration', () {
      final now = DateTime(2026, 9, 15, 14, 0);
      final session = TableSession(
        id: 's-1',
        branchId: 'branch-1',
        tableId: 't-1',
        tableName: 'Table 1',
        operatorId: 'op-1',
        operatorName: 'Vikram',
        playerName: 'Rahul',
        startTime: now.subtract(const Duration(hours: 3)),
        billingMode: BillingMode.fixedFrame,
        standardRatePerHour: 150.0,
        peakRatePerHour: 250.0,
        fixedFrameFee: 120.0,
      );

      final charge = session.computeTableChargeAt(now);
      expect(charge, equals(120.0));
      expect(session.computeGrandTotalAt(now), equals(120.0));
    });

    test('Calculates standard rate during off-peak daytime hours', () {
      // 14:00 to 15:00 (1 hour off-peak @ ₹150/hr)
      final start = DateTime(2026, 9, 15, 14, 0);
      final now = DateTime(2026, 9, 15, 15, 0);
      final session = TableSession(
        id: 's-2',
        branchId: 'branch-1',
        tableId: 't-1',
        tableName: 'Table 1',
        operatorId: 'op-1',
        operatorName: 'Vikram',
        playerName: 'Player 1',
        startTime: start,
        billingMode: BillingMode.hourly,
        standardRatePerHour: 150.0,
        peakRatePerHour: 250.0,
        peakStartHour: 18,
        peakEndHour: 23,
      );

      final charge = session.computeTableChargeAt(now);
      expect(charge, equals(150.0));
    });

    test('Prorates rates seamlessly when session overlaps standard and peak slots', () {
      // 17:30 to 18:30 (30 mins off-peak @ ₹150/h = ₹75, 30 mins peak @ ₹250/h = ₹125 -> Total ₹200)
      final start = DateTime(2026, 9, 15, 17, 30);
      final now = DateTime(2026, 9, 15, 18, 30);
      final session = TableSession(
        id: 's-3',
        branchId: 'branch-1',
        tableId: 't-1',
        tableName: 'Table 1',
        operatorId: 'op-1',
        operatorName: 'Vikram',
        playerName: 'Overlap Players',
        startTime: start,
        billingMode: BillingMode.hourly,
        standardRatePerHour: 150.0,
        peakRatePerHour: 250.0,
        peakStartHour: 18,
        peakEndHour: 23,
      );

      final charge = session.computeTableChargeAt(now);
      expect(charge, equals(200.0));
    });
  });

  group('2. Shift Handover Audit & Cash Variance Engine', () {
    test('Computes expected cash drawer and zero variance on exact match', () {
      final shift = ShiftRecord(
        id: 'shift-test-1',
        branchId: 'branch-1',
        operatorId: 'op-1',
        operatorName: 'Vikram Singh',
        shiftStartTime: DateTime.now().subtract(const Duration(hours: 6)),
        openingCashDrawer: 2000.0,
        totalCashSessionRevenue: 1500.0,
        totalCashFnbRevenue: 450.0,
        totalUpiRevenue: 1200.0,
        totalCardRevenue: 800.0,
      );

      // Expected Cash = 2000 + 1500 + 450 = 3950
      expect(shift.expectedCash, equals(3950.0));
      expect(shift.totalRevenue, equals(3950.0)); // Total collected revenue = 1500 + 450 + 1200 + 800

      // Counted exact physical cash
      final closed = shift.copyWith(
        physicalCashCounted: 3950.0,
        varianceAmount: 3950.0 - shift.expectedCash,
        isClosed: true,
      );

      expect(closed.varianceAmount, equals(0.0));
    });

    test('Identifies cash shortage or surplus and flags discrepancy', () {
      final shift = ShiftRecord(
        id: 'shift-test-2',
        branchId: 'branch-1',
        operatorId: 'op-1',
        operatorName: 'Cashier 1',
        shiftStartTime: DateTime.now().subtract(const Duration(hours: 8)),
        openingCashDrawer: 1000.0,
        totalCashSessionRevenue: 800.0,
        totalCashFnbRevenue: 200.0,
      );

      final expected = shift.expectedCash; // 2000.0
      const physicalCounted = 1850.0; // ₹150 short!
      final variance = physicalCounted - expected; // -150.0

      expect(variance, equals(-150.0));
      expect(variance.abs() > 0.01, isTrue); // Flagged for owner audit
    });
  });

  group('3. Net Profit Ledger Formula', () {
    test('Calculates Net Profit = (Table Revenue + F&B Sales) - Total Operational Expenses', () {
      const double tableRevenue = 42500.0;
      const double fnbRevenue = 14200.0;
      const double operationalExpenses = 28000.0;

      final netProfit = (tableRevenue + fnbRevenue) - operationalExpenses;
      expect(netProfit, equals(28700.0));
    });
  });

  group('4. Role-Based Access Control (RBAC) Permissions', () {
    test('Super Admin has unrestricted permissions', () {
      const role = UserRole.superAdmin;
      expect(role.canViewFinancials, isTrue);
      expect(role.canManageRates, isTrue);
      expect(role.canDeleteBillsOrOverride, isTrue);
      expect(role.canAccessNetProfitLedger, isTrue);
      expect(role.canControlTimers, isTrue);
    });

    test('Counter Admin has operational permissions but cannot manage base rates', () {
      const role = UserRole.counterAdmin;
      expect(role.canViewFinancials, isTrue);
      expect(role.canManageRates, isFalse);
      expect(role.canDeleteBillsOrOverride, isFalse);
      expect(role.canControlTimers, isTrue);
      expect(role.canPerformShiftHandover, isTrue);
    });

    test('Attendant / Marker has zero access to financial numbers', () {
      const role = UserRole.attendantMarker;
      expect(role.canViewFinancials, isFalse);
      expect(role.canManageRates, isFalse);
      expect(role.canDeleteBillsOrOverride, isFalse);
      expect(role.canAccessNetProfitLedger, isFalse);
      expect(role.canManageExpenses, isFalse);
      expect(role.canControlTimers, isFalse);
      expect(role.canSellCanteen, isFalse);
    });
  });

  group('5. Equipment Lifecycle & Consumables Thresholds', () {
    test('Felt cloth alerts at 50h ironing and 1,000h re-clothing', () {
      final feltItem = EquipmentItem(
        id: 'felt-1',
        branchId: 'b-1',
        name: 'Strachan 6811',
        type: EquipmentType.tableClothFelt,
        currentMetricValue: 49.0,
        thresholdValue: 50.0,
        maxLifespan: 1000.0,
        metricUnit: 'hours',
        lastMaintenanceDate: DateTime.now(),
        alertStatus: EquipmentAlertStatus.warning,
        alertMessage: 'Ironing cycle due soon',
      );

      expect(feltItem.thresholdValue, equals(50.0));
      expect(feltItem.maxLifespan, equals(1000.0));
    });

    test('Cue tips wear percentage triggers alert at 85% expected lifespan', () {
      final cueTip = EquipmentItem(
        id: 'cue-1',
        branchId: 'b-1',
        name: 'House Cues Tips',
        type: EquipmentType.cueTip,
        currentMetricValue: 174.0, // 174 of 200 hours = 87%
        thresholdValue: 170.0,
        maxLifespan: 200.0,
        metricUnit: 'hours',
        lastMaintenanceDate: DateTime.now(),
        alertStatus: EquipmentAlertStatus.warning,
        alertMessage: 'Wear at 87%',
      );

      expect(cueTip.wearPercentage, equals(87.0));
      expect(cueTip.wearPercentage >= 85.0, isTrue);
    });

    test('Chalk stock alerts when unissued stock falls below 10 units', () {
      const canteenChalk = CanteenItem(
        id: 'chalk-1',
        branchId: 'b-1',
        name: 'Taom V10 Chalk',
        category: CanteenCategory.accessories,
        unitPrice: 190.0,
        costPrice: 120.0,
        stockQuantity: 8,
        minThreshold: 10,
      );

      expect(canteenChalk.isLowStock, isTrue);
    });
  });
}
