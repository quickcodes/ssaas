import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/audit_log_event.dart';
import '../../../domain/entities/shift_record.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/shift_audit/shift_audit_bloc.dart';

class ShiftHandoverView extends StatefulWidget {
  const ShiftHandoverView({super.key});

  @override
  State<ShiftHandoverView> createState() => _ShiftHandoverViewState();
}

class _ShiftHandoverViewState extends State<ShiftHandoverView> {
  final _countedCashController = TextEditingController();
  final _closingNotesController = TextEditingController();
  final _newShiftOpeningCashController = TextEditingController(text: '2000');

  @override
  void dispose() {
    _countedCashController.dispose();
    _closingNotesController.dispose();
    _newShiftOpeningCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeUser = authState.currentUser;
        final activeBranch = authState.activeBranch;

        if (activeUser == null || activeBranch == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<ShiftAuditBloc, ShiftAuditState>(
          listener: (context, state) {
            if (state.alertMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.alertMessage!),
                  backgroundColor: state.alertMessage!.contains('discrepancy')
                      ? AppColors.tableOccupied
                      : AppColors.tableAvailable,
                ),
              );
            }
          },
          builder: (context, state) {
            final shift = state.currentShift;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Shift Duty Banner
                  _buildShiftHeader(shift, activeUser),
                  const SizedBox(height: 20),

                  if (shift != null) ...[
                    // Cash Drawer Tally & Variance Calculator
                    _buildCashDrawerTallyCard(context, shift),
                    const SizedBox(height: 24),
                  ] else ...[
                    // No active shift -> Prompt to start new shift
                    _buildStartShiftCard(context, activeUser, activeBranch.id),
                    const SizedBox(height: 24),
                  ],

                  // Tamper-Proof Audit Trail Feed
                  _buildAuditTrailSection(state.auditLogs),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShiftHeader(ShiftRecord? shift, dynamic activeUser) {
    final isActive = shift != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.brandAccent.withAlpha(120) : AppColors.cardBorderStroke,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brandAccent.withAlpha(30) : AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.lock_clock : Icons.no_accounts,
                  color: isActive ? AppColors.brandAccentLight : AppColors.secondaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'ACTIVE SHIFT DUTY: #${shift.id.substring(0, 8)}' : 'NO ACTIVE SHIFT IN DRAWER',
                    style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Operator: ${shift.operatorName} • Started: ${AppFormatters.timeOnly(shift.shiftStartTime)}'
                        : 'Current Logged Operator: ${activeUser.name}',
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.tableAvailable.withAlpha(25) : AppColors.tableMaintenance.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? AppColors.tableAvailable.withAlpha(120) : AppColors.tableMaintenance.withAlpha(120),
              ),
            ),
            child: Text(
              isActive ? 'REGISTER OPEN' : 'REGISTER CLOSED',
              style: TextStyle(
                color: isActive ? AppColors.tableAvailable : AppColors.tableMaintenance,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashDrawerTallyCard(BuildContext context, ShiftRecord shift) {
    final expectedCash = shift.expectedCash;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'MANDATORY END-OF-SHIFT CASH DRAWER AUDIT',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Before handover, physical currency must be counted. The system logs any discrepancy permanently.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Drawer Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildDrawerMetric(
                  'Opening Drawer',
                  AppFormatters.currency(shift.openingCashDrawer),
                  AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrawerMetric(
                  'Table Cash',
                  AppFormatters.currency(shift.totalCashSessionRevenue),
                  AppColors.tableAvailable,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrawerMetric(
                  'Canteen Cash',
                  AppFormatters.currency(shift.totalCashFnbRevenue),
                  AppColors.tableAvailable,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDrawerMetric(
                  'Digital (UPI/Card)',
                  AppFormatters.currency(shift.totalUpiRevenue + shift.totalCardRevenue),
                  AppColors.tableReserved,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expected Cash Highlight Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Computed Expected Cash', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    SizedBox(height: 2),
                    Text('Opening Cash + Cash Sessions + Cash F&B', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                  ],
                ),
                Text(
                  AppFormatters.currency(expectedCash),
                  style: const TextStyle(color: AppColors.tableAvailable, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Physical Count Input and Handover Submit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _countedCashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Counted Physical Cash in Drawer *',
                    hintText: 'Enter exact cash counted',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.secondaryText),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _closingNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Supervisor / Handover Notes',
                    hintText: 'e.g. Verified by night shift cashier',
                    prefixIcon: Icon(Icons.notes, color: AppColors.secondaryText),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _executeShiftClose(context, shift),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('SUBMIT AUDIT & CLOSE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStartShiftCard(BuildContext context, dynamic activeUser, String branchId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'START NEW OPERATOR SHIFT',
            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Logging duty under active cashier: ${activeUser.name}. Enter opening float amount in cash drawer.',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newShiftOpeningCashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Cash Drawer Float (₹) *',
                    hintText: '2000',
                    prefixText: '₹ ',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: () {
                  final opening = double.tryParse(_newShiftOpeningCashController.text.trim()) ?? 2000.0;
                  final newShift = ShiftRecord(
                    id: const Uuid().v4(),
                    branchId: branchId,
                    operatorId: activeUser.id,
                    operatorName: activeUser.name,
                    shiftStartTime: DateTime.now(),
                    openingCashDrawer: opening,
                  );
                  context.read<ShiftAuditBloc>().add(StartNewShiftEvent(newShift));
                },
                icon: const Icon(Icons.login),
                label: const Text('OPEN SHIFT REGISTER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tableAvailable,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailSection(List<AuditLogEvent> logs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: AppColors.brandAccentLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TAMPER-PROOF AUDIT TRAIL FEED',
                    style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorderStroke),
                ),
                child: Text('${logs.length} Logged Events', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'All timer resets, discounts, pricing overrides, bill cancellations, and cash discrepancies are permanently recorded.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorderStroke),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorderStroke, height: 16),
            itemBuilder: (context, index) {
              final log = logs[index];
              Color sevColor;
              switch (log.severity) {
                case AuditSeverity.info:
                  sevColor = AppColors.brandAccentLight;
                  break;
                case AuditSeverity.warning:
                  sevColor = AppColors.tableMaintenance;
                  break;
                case AuditSeverity.criticalAlert:
                  sevColor = AppColors.tableOccupied;
                  break;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: log.isTamperFlag ? AppColors.tableOccupied.withAlpha(15) : AppColors.inputSurface.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: log.isTamperFlag ? AppColors.tableOccupied.withAlpha(80) : AppColors.cardBorderStroke,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(log.action, style: TextStyle(color: sevColor, fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(
                                AppFormatters.dateTime(log.timestamp),
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.details,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 12, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tagged Operator: ${log.operatorName}',
                            style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _executeShiftClose(BuildContext context, ShiftRecord shift) {
    final text = _countedCashController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter physical cash counted')),
      );
      return;
    }

    final counted = double.tryParse(text) ?? 0.0;
    final notes = _closingNotesController.text.trim();

    context.read<ShiftAuditBloc>().add(CloseShiftHandoverEvent(
          shiftId: shift.id,
          countedPhysicalCash: counted,
          closingNotes: notes.isEmpty ? 'Handover completed' : notes,
        ));

    _countedCashController.clear();
    _closingNotesController.clear();
  }
}
