import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../domain/entities/table_billing_item.dart';
import '../../../domain/entities/table_history_record.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/fade_slide_transition.dart';
import 'add_table_item_dialog.dart';
import 'add_table_screen.dart';
import 'checkout_session_dialog.dart';
import 'start_session_dialog.dart';
import 'table_card.dart';
import 'table_configuration_dialog.dart';
import '../dashboard/user_online_status_dialog.dart';

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

  void _showAddTableDialog(BuildContext context, String companyId) async {
    final newTable = await AppNavigation.pushSmooth<ClubTable>(
      context,
      AddTableScreen(companyId: companyId),
    );

    if (newTable != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(CreateTableEvent(newTable));
    }
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
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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

            final isMobile = Responsive.isMobile(context);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Summary & Admin Add Table
                  if (isMobile) ...[
                    if (activeUser.isAdmin)
                      ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.light();
                          _showAddTableDialog(context, activeCompany.id);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Snooker Table'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (activeUser.isAdmin) const SizedBox(height: 12),
                    _buildFloorSummaryBar(
                      available: availableCount,
                      occupied: occupiedCount,
                      maintenance: maintenanceCount,
                      reserved: reservedCount,
                    ),
                  ] else ...[
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
                            onPressed: () {
                              AppHaptics.light();
                              _showAddTableDialog(context, activeCompany.id);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Table'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Filter Row
                  _buildFilterRow(
                    context,
                    matrixState.filterStatus,
                    totalCount: allTables.length,
                    availableCount: availableCount,
                    occupiedCount: occupiedCount,
                    maintenanceCount: maintenanceCount,
                    reservedCount: reservedCount,
                  ),
                  const SizedBox(height: 20),

                  // Tables Grid Matrix
                  if (tables.isEmpty)
                    EmptyStateCard(
                      icon: Icons.sports_esports_outlined,
                      title: matrixState.filterStatus != null
                          ? 'No ${matrixState.filterStatus!.displayName} Tables'
                          : 'No Snooker Tables Found',
                      subtitle: activeUser.isAdmin
                          ? 'Get started by creating your first snooker table to begin tracking live sessions.'
                          : 'No tables currently match this filter criteria.',
                      actionLabel: activeUser.isAdmin ? 'Add First Table' : null,
                      onAction: activeUser.isAdmin
                          ? () => _showAddTableDialog(context, activeCompany.id)
                          : null,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 620) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 1050) {
                          crossAxisCount = 2;
                        } else if (constraints.maxWidth < 1500) {
                          crossAxisCount = 3;
                        } else {
                          crossAxisCount = 4;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 365,
                          ),
                          itemCount: tables.length,
                          itemBuilder: (context, index) {
                            final table = tables[index];
                            final session =
                                matrixState.getSessionForTable(table.id);

                            return FadeSlideTransitionWidget(
                              index: index,
                              child: TableCard(
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
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    TableStatus? currentFilter, {
    required int totalCount,
    required int availableCount,
    required int occupiedCount,
    required int maintenanceCount,
    required int reservedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            null,
            'All ($totalCount)',
            currentFilter == null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.available,
            'Available ($availableCount)',
            currentFilter == TableStatus.available,
            color: AppColors.tableAvailable,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.occupied,
            'Running ($occupiedCount)',
            currentFilter == TableStatus.occupied,
            color: AppColors.tableOccupied,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.maintenance,
            'Maintenance ($maintenanceCount)',
            currentFilter == TableStatus.maintenance,
            color: AppColors.tableMaintenance,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            TableStatus.reserved,
            'Booked ($reservedCount)',
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
        AppHaptics.selection();
        context.read<FloorMatrixBloc>().add(FilterStatusChangedEvent(status));
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
    if (!activeUser.isOnline) {
      final activeCompany = context.read<AuthBloc>().state.activeCompany;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Only the active Online operator can start tables. Please switch to Online first.',
          ),
          backgroundColor: AppColors.tableOccupied,
          action: activeCompany != null
              ? SnackBarAction(
                  label: 'GO ONLINE',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserOnlineStatusDialog(
                        currentUser: activeUser,
                        activeCompany: activeCompany,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      return;
    }

    final session = await AppNavigation.pushSmooth<TableSession>(
      context,
      StartSessionScreen(
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

    final item = await AppNavigation.pushSmooth<TableBillingItem>(
      context,
      AddTableItemScreen(
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

    if (!activeUser.isOnline) {
      final activeCompany = context.read<AuthBloc>().state.activeCompany;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Only the active Online operator can close tables. Please switch to Online first.',
          ),
          backgroundColor: AppColors.tableOccupied,
          action: activeCompany != null
              ? SnackBarAction(
                  label: 'GO ONLINE',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserOnlineStatusDialog(
                        currentUser: activeUser,
                        activeCompany: activeCompany,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      return;
    }

    final activeCompany = context.read<AuthBloc>().state.activeCompany;
    final historyRecord = await AppNavigation.pushSmooth<TableHistoryRecord>(
      context,
      CheckoutSessionScreen(
        session: session,
        now: now,
        activeOperator: activeUser,
        dueBufferAmount:
            activeCompany?.dueBufferAmount ?? Constants.dueBufferAmount,
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
    final updated = await AppNavigation.pushSmooth<ClubTable>(
      context,
      TableConfigurationScreen(table: table),
    );

    if (updated != null && context.mounted) {
      context.read<FloorMatrixBloc>().add(SaveTableConfigurationEvent(updated));
    }
  }
}
