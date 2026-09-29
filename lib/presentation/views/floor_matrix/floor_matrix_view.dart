import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/club_reminder.dart';
import '../../../domain/entities/club_table.dart';
import '../../../domain/entities/company.dart';
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
import 'manage_table_items_dialog.dart';
import 'start_session_dialog.dart';
import 'table_card.dart';
import 'table_configuration_dialog.dart';
import '../dashboard/reminder_details_dialog.dart';
import '../dashboard/user_online_status_dialog.dart';

class FloorMatrixView extends StatefulWidget {
  const FloorMatrixView({super.key});

  @override
  State<FloorMatrixView> createState() => _FloorMatrixViewState();
}

class _FloorMatrixViewState extends State<FloorMatrixView> {
  List<StockItem> _canteenItems = [];
  Timer? _snackBarDismissTimer;

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

            final isMobile = Responsive.isMobile(context);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Upcoming Reminders (Alert Banner: appears before 1 hour of scheduled time)
                  if (matrixState.activeUpcomingReminders.isNotEmpty) ...[
                    _buildUpcomingRemindersBanner(
                      context,
                      matrixState.activeUpcomingReminders,
                      activeCompany,
                      activeUser,
                    ),
                    const SizedBox(height: 14),
                  ],

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
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildFloorSummaryBar(
                            available: availableCount,
                            occupied: occupiedCount,
                            maintenance: maintenanceCount,
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
                            mainAxisExtent: 390,
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
                                  activeUser,
                                ),
                                onManageItems: session != null
                                    ? () => _handleManageItems(
                                          context,
                                          activeCompany.id,
                                          session,
                                          activeUser,
                                        )
                                    : null,
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
                                onDeleteTable: activeUser.isAdmin
                                    ? () => _handleDeleteTable(
                                          context,
                                          activeCompany.id,
                                          table,
                                        )
                                    : null,
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

  @override
  void dispose() {
    _snackBarDismissTimer?.cancel();
    super.dispose();
  }

  void _showOfflineOperatorSnackBar(
    BuildContext context,
    UserAccount activeUser,
    String actionDescription,
  ) {
    final activeCompany = context.read<AuthBloc>().state.activeCompany;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    _snackBarDismissTimer?.cancel();

    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Only the active Online operator can $actionDescription. Please switch to Online first.',
        ),
        backgroundColor: AppColors.tableOccupied,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: activeCompany != null
            ? SnackBarAction(
                label: 'GO ONLINE',
                textColor: Colors.white,
                onPressed: () {
                  _snackBarDismissTimer?.cancel();
                  messenger.hideCurrentSnackBar();
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

    // Explicit auto-dismissal timer to ensure the snackbar dismisses even on devices with accessibility services active
    _snackBarDismissTimer = Timer(const Duration(seconds: 4), () {
      try {
        controller.close();
      } catch (_) {}
    });

    controller.closed.then((_) {
      _snackBarDismissTimer?.cancel();
    });
  }

  void _handleStartSession(
    BuildContext context,
    ClubTable table,
    UserAccount activeUser,
  ) async {
    if (!activeUser.isOnline) {
      _showOfflineOperatorSnackBar(context, activeUser, 'start tables');
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
    UserAccount activeUser,
  ) async {
    if (session == null) return;

    if (!activeUser.isOnline) {
      _showOfflineOperatorSnackBar(
        context,
        activeUser,
        'add canteen items to tables',
      );
      return;
    }

    final item = await AppNavigation.pushSmooth<TableBillingItem>(
      context,
      AddTableItemScreen(
        canteenItems: _canteenItems,
        tableName: session.tableName,
        existingItemsCount: session.items.length,
        onManageExistingItems: () => _handleManageItems(
          context,
          companyId,
          session,
          activeUser,
        ),
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

  void _handleManageItems(
    BuildContext context,
    String companyId,
    TableSession? session,
    UserAccount activeUser,
  ) {
    if (session == null) return;
    showDialog(
      context: context,
      builder: (ctx) => ManageTableItemsDialog(
        companyId: companyId,
        sessionId: session.id,
        tableName: session.tableName,
        activeOperator: activeUser,
        onAddMoreItems: () => _handleAddItem(
          context,
          companyId,
          session,
          activeUser,
        ),
      ),
    );
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
      _showOfflineOperatorSnackBar(context, activeUser, 'close tables');
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

  void _handleDeleteTable(
    BuildContext context,
    String companyId,
    ClubTable table,
  ) {
    AppHaptics.medium();
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tableOccupied.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.tableOccupied,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Table?',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete table "${table.name}"? This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<FloorMatrixBloc>().add(
                    DeleteTableEvent(
                      companyId: companyId,
                      tableId: table.id,
                      tableName: table.name,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Table'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRemindersBanner(
    BuildContext context,
    List<ClubReminder> upcomingReminders,
    Company company,
    UserAccount user,
  ) {
    if (upcomingReminders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: upcomingReminders.map((reminder) {
        final now = DateTime.now();
        final diff = reminder.remindAt.difference(now);
        final String countdownText;
        if (diff.isNegative) {
          final pastMinutes = diff.inMinutes.abs();
          if (pastMinutes < 60) {
            countdownText = 'Started $pastMinutes mins ago';
          } else {
            countdownText = 'Started ${diff.inHours.abs()}h ago';
          }
        } else {
          final remainingMinutes = diff.inMinutes;
          if (remainingMinutes == 0) {
            countdownText = 'Starting now!';
          } else if (remainingMinutes < 60) {
            countdownText = 'In $remainingMinutes mins';
          } else {
            final hours = diff.inHours;
            final mins = remainingMinutes % 60;
            countdownText = 'In ${hours}h ${mins}m';
          }
        }

        final timeFormatted = DateFormat('hh:mm a').format(reminder.remindAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFB300).withAlpha(120),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                ReminderDetailsDialog.show(
                  context,
                  reminder: reminder,
                  activeCompany: company,
                  currentUser: user,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withAlpha(35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB300).withAlpha(140),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFFFB300),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'UPCOMING BOOKING / REMINDER',
                                  style: TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300).withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$countdownText ($timeFormatted)',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            reminder.description,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss button
                    Tooltip(
                      message: 'Mark as done / Dismiss',
                      child: InkWell(
                        onTap: () {
                          AppHaptics.light();
                          context.read<FloorMatrixBloc>().add(
                                DismissReminderEvent(
                                  companyId: company.id,
                                  reminderId: reminder.id,
                                ),
                              );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.cardBorderStroke,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.done,
                                size: 14,
                                color: AppColors.tableAvailable,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Dismiss',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFFFB300),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
