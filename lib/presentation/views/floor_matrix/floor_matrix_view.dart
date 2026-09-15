import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/table_session.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/canteen_pos/canteen_pos_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import 'checkout_session_dialog.dart';
import 'start_session_dialog.dart';
import 'table_card.dart';
import 'table_configuration_dialog.dart';
import 'table_qr_modal.dart';

class FloorMatrixView extends StatelessWidget {
  final VoidCallback? onOpenCanteen;
  const FloorMatrixView({super.key, this.onOpenCanteen});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeUser = authState.currentUser;
        final activeBranch = authState.activeBranch;

        if (activeUser == null || activeBranch == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
          builder: (context, matrixState) {
            if (matrixState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final tables = matrixState.filteredTables;
            final allTables = matrixState.tables;
            final availableCount = allTables
                .where((t) => t.status == TableStatus.available)
                .length;
            final occupiedCount = allTables
                .where((t) => t.status == TableStatus.occupied)
                .length;
            final maintenanceCount = allTables
                .where((t) => t.status == TableStatus.maintenance)
                .length;
            final reservedCount = allTables
                .where((t) => t.status == TableStatus.reserved)
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Summary Bar
                  _buildFloorSummaryBar(
                    available: availableCount,
                    occupied: occupiedCount,
                    maintenance: maintenanceCount,
                    reserved: reservedCount,
                  ),
                  const SizedBox(height: 16),

                  // Filter Row
                  _buildFilterRow(context, matrixState.filterStatus),
                  const SizedBox(height: 20),

                  // Table Grid Matrix
                  if (tables.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.sports_esports_outlined,
                            size: 48,
                            color: AppColors.secondaryText,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tables found matching filter',
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 650) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 1100) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tables.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.05,
                              ),
                          itemBuilder: (context, index) {
                            final table = tables[index];
                            final session = matrixState.getSessionForTable(
                              table.id,
                            );

                            return TableCard(
                              table: table,
                              session: session,
                              now: matrixState.currentTickerTime,
                              activeOperator: activeUser,
                              onStartSession: () => _handleStartSession(
                                context,
                                table,
                                activeBranch,
                                activeUser,
                              ),
                              onPauseSession: () {
                                if (session != null) {
                                  context.read<FloorMatrixBloc>().add(
                                    PauseTableSessionEvent(session.id),
                                  );
                                }
                              },
                              onResumeSession: () {
                                if (session != null) {
                                  context.read<FloorMatrixBloc>().add(
                                    ResumeTableSessionEvent(session.id),
                                  );
                                }
                              },
                              onCheckoutSession: () => _handleCheckoutSession(
                                context,
                                table,
                                session,
                                matrixState.currentTickerTime,
                                activeUser,
                              ),
                              onAddFnb: () =>
                                  _handleAddFnbToTable(context, session),
                              onOpenQrHub: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => TableQrCustomerHubModal(
                                    table: table,
                                    session: session,
                                    branch: activeBranch,
                                    now: matrixState.currentTickerTime,
                                  ),
                                );
                              },
                              onUpdateStatus: (newStatus) {
                                context.read<FloorMatrixBloc>().add(
                                  UpdateTableStatusDirectEvent(
                                    table.id,
                                    newStatus,
                                  ),
                                );
                              },
                              onConfigureRates: () async {
                                final updated = await showDialog<ClubTable>(
                                  context: context,
                                  builder: (_) =>
                                      TableConfigurationDialog(table: table),
                                );
                                if (updated != null && context.mounted) {
                                  context.read<FloorMatrixBloc>().add(
                                    SaveTableConfigurationEvent(updated),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloorSummaryBar({
    required int available,
    required int occupied,
    required int maintenance,
    required int reserved,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricPill(
              'Open Tables',
              available.toString(),
              AppColors.tableAvailable,
              Icons.check_circle_outline,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Occupied (Active)',
              occupied.toString(),
              AppColors.tableOccupied,
              Icons.play_circle_fill,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Maintenance / Felt',
              maintenance.toString(),
              AppColors.tableMaintenance,
              Icons.build_circle_outlined,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Reserved',
              reserved.toString(),
              AppColors.tableReserved,
              Icons.bookmark_border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(height: 32, width: 1, color: AppColors.cardBorderStroke);
  }

  Widget _buildMetricPill(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, TableStatus? currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context, null, 'All Tables', currentFilter == null),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.available,
            'Available (Open)',
            currentFilter == TableStatus.available,
            color: AppColors.tableAvailable,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.occupied,
            'Occupied (Running)',
            currentFilter == TableStatus.occupied,
            color: AppColors.tableOccupied,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.maintenance,
            'Maintenance & Ironing',
            currentFilter == TableStatus.maintenance,
            color: AppColors.tableMaintenance,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.reserved,
            'Reserved',
            currentFilter == TableStatus.reserved,
            color: AppColors.tableReserved,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    TableStatus? status,
    String label,
    bool isSelected, {
    Color? color,
  }) {
    final chipColor = color ?? AppColors.brandAccentLight;
    return InkWell(
      onTap: () {
        context.read<FloorMatrixBloc>().add(FilterStatusChangedEvent(status));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(35) : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorderStroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryText
                    : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStartSession(
    BuildContext context,
    ClubTable table,
    dynamic branch,
    dynamic activeUser,
  ) async {
    final session = await showDialog<TableSession>(
      context: context,
      builder: (_) => StartSessionDialog(
        table: table,
        branch: branch,
        activeOperator: activeUser,
      ),
    );

    if (session != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(StartTableSessionEvent(session));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table "${table.name}" clock started for ${session.playerName}',
          ),
          backgroundColor: AppColors.cardSurface,
        ),
      );
    }
  }

  void _handleCheckoutSession(
    BuildContext context,
    ClubTable table,
    TableSession? session,
    DateTime now,
    dynamic activeUser,
  ) async {
    if (session == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CheckoutSessionDialog(
        session: session,
        tabItems: const [],
        now: now,
        canOverrideDiscount: activeUser.role.canDeleteBillsOrOverride,
      ),
    );

    if (result != null && context.mounted) {
      final paymentMethod = result['paymentMethod'] as PaymentMethod;
      final finalTableAmount = result['finalTableAmount'] as double;
      final finalTotalAmount = result['finalTotalAmount'] as double;

      context.read<FloorMatrixBloc>().add(
        CompleteTableSessionEvent(
          sessionId: session.id,
          paymentMethod: paymentMethod,
          finalTableAmount: finalTableAmount,
          finalTotalAmount: finalTotalAmount,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settled ${table.name}: Received ₹${finalTotalAmount.toStringAsFixed(2)} via ${paymentMethod.displayName}',
          ),
          backgroundColor: AppColors.tableAvailable,
        ),
      );
    }
  }

  void _handleAddFnbToTable(BuildContext context, TableSession? session) {
    if (session == null) return;
    context.read<CanteenPosBloc>().add(SetTargetSessionEvent(session.id));
    onOpenCanteen?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Canteen POS set to add items to Table "${session.tableName}" tab',
        ),
        backgroundColor: AppColors.brandAccent,
      ),
    );
  }
}
