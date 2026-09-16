import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../domain/entities/table_billing_item.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import 'add_table_item_dialog.dart';
import 'checkout_session_dialog.dart';
import 'start_session_dialog.dart';
import 'table_card.dart';
import 'table_configuration_dialog.dart';

class FloorMatrixView extends StatefulWidget {
  const FloorMatrixView({super.key});

  @override
  State<FloorMatrixView> createState() => _FloorMatrixViewState();
}

class _FloorMatrixViewState extends State<FloorMatrixView> {
  List<StockItem> _canteenItems = [];

  @override
  void initState() {
    super.initState();
    _loadCanteenStock();
  }

  void _loadCanteenStock() {
    final companyId = context.read<AuthBloc>().state.activeCompany?.id;
    if (companyId != null) {
      sl<FirestoreService>().watchFoodCanteen(companyId).listen((items) {
        if (mounted) {
          setState(() => _canteenItems = items);
        }
      });
    }
  }

  void _showAddTableDialog(BuildContext context, String companyId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '120');
    final specsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: AppColors.brandAccentLight),
            SizedBox(width: 10),
            Text(
              'Add Snooker Table',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Table Name *',
                  hintText: 'e.g. Table 1 (Star Tournament)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'General Hourly Price *',
                  hintText: 'e.g. 120',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specs / Description',
                  hintText: 'e.g. 12ft Standard Slate Snooker Table',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final general = double.tryParse(priceCtrl.text.trim());
              if (nameCtrl.text.trim().isEmpty || general == null || general <= 0) {
                return;
              }

              final newTable = ClubTable(
                id: const Uuid().v4(),
                companyId: companyId,
                name: nameCtrl.text.trim(),
                generalPrice: general,
                specsDescription: specsCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              Navigator.of(dialogCtx).pop();
              context.read<FloorMatrixBloc>().add(CreateTableEvent(newTable));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
            ),
            child: const Text('Add Table'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeUser = authState.currentUser;
        final activeCompany = authState.activeCompany;

        if (activeUser == null || activeCompany == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<FloorMatrixBloc, FloorMatrixState>(
          listenWhen: (previous, current) =>
              (current.successMessage != null &&
                  current.successMessage != previous.successMessage) ||
              (current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage),
          listener: (context, state) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.tableAvailable,
                ),
              );
              context
                  .read<FloorMatrixBloc>()
                  .add(const ClearFloorMatrixMessagesEvent());
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.tableOccupied,
                ),
              );
              context
                  .read<FloorMatrixBloc>()
                  .add(const ClearFloorMatrixMessagesEvent());
            }
          },
          builder: (context, matrixState) {
            if (matrixState.isLoading && matrixState.tables.isEmpty) {
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
                  // Top Row: Summary & Admin Add Table
                  Row(
                    children: [
                      Expanded(
                        child: _buildFloorSummaryBar(
                          available: availableCount,
                          occupied: occupiedCount,
                          maintenance: maintenanceCount,
                          reserved: reservedCount,
                        ),
                      ),
                      if (activeUser.isAdmin) ...[
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddTableDialog(context, activeCompany.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Table'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Row
                  _buildFilterRow(context, matrixState.filterStatus),
                  const SizedBox(height: 20),

                  // Tables Grid Matrix
                  if (tables.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.sports_esports_outlined,
                            size: 48,
                            color: AppColors.secondaryText,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No snooker tables found.',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (activeUser.isAdmin) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Click "Add Table" above to create your first snooker table.',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 360,
                          ),
                          itemCount: tables.length,
                          itemBuilder: (context, index) {
                            final table = tables[index];
                            final session =
                                matrixState.getSessionForTable(table.id);

                            return TableCard(
                              table: table,
                              session: session,
                              now: matrixState.currentTickerTime,
                              activeOperator: activeUser,
                              onStartSession: () => _handleStartSession(
                                context,
                                table,
                                activeUser,
                              ),
                              onPauseSession: () {
                                if (session != null) {
                                  context.read<FloorMatrixBloc>().add(
                                        PauseTableSessionEvent(
                                          activeCompany.id,
                                          session.id,
                                        ),
                                      );
                                }
                              },
                              onResumeSession: () {
                                if (session != null) {
                                  context.read<FloorMatrixBloc>().add(
                                        ResumeTableSessionEvent(
                                          activeCompany.id,
                                          session.id,
                                        ),
                                      );
                                }
                              },
                              onAddItem: () => _handleAddItem(
                                context,
                                activeCompany.id,
                                session,
                              ),
                              onCheckoutSession: () => _handleCheckoutSession(
                                context,
                                activeCompany.id,
                                table,
                                session,
                                matrixState.currentTickerTime,
                                activeUser,
                              ),
                              onUpdateStatus: (newStatus) {
                                context.read<FloorMatrixBloc>().add(
                                      UpdateTableStatusDirectEvent(
                                        activeCompany.id,
                                        table.id,
                                        newStatus,
                                      ),
                                    );
                              },
                              onConfigureRates: () =>
                                  _handleConfigureRates(context, table),
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
              'Available',
              available.toString(),
              AppColors.tableAvailable,
              Icons.check_circle_outline,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Running (Occupied)',
              occupied.toString(),
              AppColors.tableOccupied,
              Icons.play_circle_fill,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Maintenance',
              maintenance.toString(),
              AppColors.tableMaintenance,
              Icons.build_circle_outlined,
            ),
            _buildMetricDivider(),
            _buildMetricPill(
              'Booked',
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
    return Container(
      height: 28,
      width: 1,
      color: AppColors.cardBorderStroke,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
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
          _buildFilterChip(
            context,
            null,
            'All Tables',
            currentFilter == null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.available,
            'Available',
            currentFilter == TableStatus.available,
            color: AppColors.tableAvailable,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.occupied,
            'Running',
            currentFilter == TableStatus.occupied,
            color: AppColors.tableOccupied,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.maintenance,
            'Maintenance',
            currentFilter == TableStatus.maintenance,
            color: AppColors.tableMaintenance,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.reserved,
            'Booked',
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
    UserAccount activeUser,
  ) async {
    final session = await showDialog<TableSession>(
      context: context,
      builder: (_) => StartSessionDialog(
        table: table,
        activeOperator: activeUser,
      ),
    );

    if (session != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(StartTableSessionEvent(session));
    }
  }

  void _handleAddItem(
    BuildContext context,
    String companyId,
    TableSession? session,
  ) async {
    if (session == null) return;

    final item = await showDialog<TableBillingItem>(
      context: context,
      builder: (_) => AddTableItemDialog(
        canteenItems: _canteenItems,
        tableName: session.tableName,
      ),
    );

    if (item != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(
            AddBillingItemEvent(
              companyId: companyId,
              sessionId: session.id,
              item: item,
            ),
          );
    }
  }

  void _handleCheckoutSession(
    BuildContext context,
    String companyId,
    ClubTable table,
    TableSession? session,
    DateTime now,
    UserAccount activeUser,
  ) async {
    if (session == null) return;

    final historyRecord = await showDialog<TableHistoryRecord>(
      context: context,
      builder: (_) => CheckoutSessionDialog(
        session: session,
        now: now,
        activeOperator: activeUser,
      ),
    );

    if (historyRecord != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(
            CloseTableSessionEvent(
              companyId: companyId,
              sessionId: session.id,
              historyRecord: historyRecord,
            ),
          );
    }
  }

  void _handleConfigureRates(BuildContext context, ClubTable table) async {
    final updated = await showDialog<ClubTable>(
      context: context,
      builder: (_) => TableConfigurationDialog(table: table),
    );

    if (updated != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(SaveTableConfigurationEvent(updated));
    }
  }
}
