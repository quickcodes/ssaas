import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/equipment_item.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/equipment/equipment_bloc.dart';

class EquipmentLifecycleView extends StatelessWidget {
  const EquipmentLifecycleView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeBranch = authState.activeBranch;
        final activeUser = authState.currentUser;
        if (activeBranch == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<EquipmentBloc, EquipmentState>(
          listener: (context, state) {
            if (state.actionSuccess != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccess!),
                  backgroundColor: AppColors.tableAvailable,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = state.filteredItems;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeUser?.role.canManageRates ?? false)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showEquipmentDialog(context, activeBranch.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Add equipment tracker'),
                      ),
                    ),
                  // Alert Banner if items require maintenance
                  if (state.alertCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.tableMaintenance.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.tableMaintenance.withAlpha(140),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.tableMaintenance,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.alertCount} Equipment Consumables Require Maintenance',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Club felt ironing cycles, cue tip wear thresholds, or low chalk stock require attention.',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context,
                          null,
                          'All Equipment',
                          state.selectedType == null,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          EquipmentType.tableClothFelt,
                          'Table Felt (Ironing / Cloth)',
                          state.selectedType == EquipmentType.tableClothFelt,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          EquipmentType.cueTip,
                          'Cue Tips Wear',
                          state.selectedType == EquipmentType.cueTip,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          EquipmentType.chalkBlock,
                          'Chalk Blocks',
                          state.selectedType == EquipmentType.chalkBlock,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          EquipmentType.ballSet,
                          'Ball Polishing Cycles',
                          state.selectedType == EquipmentType.ballSet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid of equipment cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      if (constraints.maxWidth < 750) {
                        crossAxisCount = 1;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.6,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildEquipmentCard(
                            context,
                            item,
                            activeBranch.id,
                            activeUser?.role.canManageRates ?? false,
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

  Widget _buildFilterChip(
    BuildContext context,
    EquipmentType? type,
    String label,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () =>
          context.read<EquipmentBloc>().add(FilterEquipmentTypeEvent(type)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandAccent.withAlpha(40)
              : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandAccent
                : AppColors.cardBorderStroke,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    EquipmentItem item,
    String branchId,
    bool canEdit,
  ) {
    Color alertColor;
    switch (item.alertStatus) {
      case EquipmentAlertStatus.normal:
        alertColor = AppColors.tableAvailable;
        break;
      case EquipmentAlertStatus.warning:
        alertColor = AppColors.tableMaintenance;
        break;
      case EquipmentAlertStatus.critical:
        alertColor = AppColors.tableOccupied;
        break;
    }

    final wear = item.wearPercentage;

    return InkWell(
      onLongPress: canEdit
          ? () => _showEquipmentDialog(context, branchId, item)
          : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.alertStatus != EquipmentAlertStatus.normal
                ? alertColor.withAlpha(120)
                : AppColors.cardBorderStroke,
            width: item.alertStatus != EquipmentAlertStatus.normal ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Name and Alert status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.tableName != null)
                        Text(
                          'Assigned: ${item.tableName!}',
                          style: const TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: alertColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: alertColor.withAlpha(120)),
                  ),
                  child: Text(
                    item.alertStatus.displayName.toUpperCase(),
                    style: TextStyle(
                      color: alertColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // Wear / Consumption Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.currentMetricValue.toStringAsFixed(1)} / ${item.maxLifespan.toStringAsFixed(0)} ${item.metricUnit}',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${wear.toStringAsFixed(0)}% Used',
                      style: TextStyle(
                        color: alertColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (wear / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.inputSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(alertColor),
                  ),
                ),
              ],
            ),

            // Alert Message snippet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.inputSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: alertColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.alertMessage,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Action Button based on Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last: ${item.lastMaintenanceDate.toLocal().toString().substring(0, 10)}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                _buildMaintenanceActionBtn(context, item, branchId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEquipmentDialog(
    BuildContext context,
    String branchId, [
    EquipmentItem? existing,
  ]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final max = TextEditingController(
      text: existing?.maxLifespan.toString() ?? '100',
    );
    final current = TextEditingController(
      text: existing?.currentMetricValue.toString() ?? '0',
    );
    var type = existing?.type ?? EquipmentType.cueTip;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Text(
            existing == null
                ? 'Add equipment tracker'
                : 'Edit equipment tracker',
            style: const TextStyle(color: AppColors.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Equipment name'),
              ),
              TextField(
                controller: current,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current usage / stock',
                ),
              ),
              TextField(
                controller: max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected lifespan / capacity',
                ),
              ),
              DropdownButtonFormField<EquipmentType>(
                initialValue: type,
                dropdownColor: AppColors.cardSurface,
                items: EquipmentType.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? type),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final maxValue = double.tryParse(max.text),
                    currentValue = double.tryParse(current.text);
                if (name.text.trim().isEmpty ||
                    maxValue == null ||
                    currentValue == null ||
                    maxValue <= 0) {
                  return;
                }
                final unit = type == EquipmentType.chalkBlock
                    ? 'units'
                    : type == EquipmentType.ballSet
                    ? 'sessions'
                    : 'hours';
                final item =
                    existing?.copyWith(
                      name: name.text.trim(),
                      type: type,
                      currentMetricValue: currentValue,
                      maxLifespan: maxValue,
                      thresholdValue: maxValue * .85,
                      metricUnit: unit,
                    ) ??
                    EquipmentItem(
                      id: const Uuid().v4(),
                      branchId: branchId,
                      name: name.text.trim(),
                      type: type,
                      currentMetricValue: currentValue,
                      thresholdValue: maxValue * .85,
                      maxLifespan: maxValue,
                      metricUnit: unit,
                      lastMaintenanceDate: DateTime.now(),
                      alertStatus: EquipmentAlertStatus.normal,
                      alertMessage: 'Configured manually.',
                    );
                context.read<EquipmentBloc>().add(SaveEquipmentItemEvent(item));
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceActionBtn(
    BuildContext context,
    EquipmentItem item,
    String branchId,
  ) {
    if (item.type == EquipmentType.chalkBlock) {
      return OutlinedButton.icon(
        onPressed: () {
          context.read<EquipmentBloc>().add(
            ReplenishChalkAction(branchId: branchId, count: 20),
          );
        },
        icon: const Icon(Icons.add_box_outlined, size: 14),
        label: const Text(
          '+ Restock 20 Chalks',
          style: TextStyle(fontSize: 11),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else if (item.type == EquipmentType.tableClothFelt) {
      return ElevatedButton.icon(
        onPressed: () {
          context.read<EquipmentBloc>().add(
            LogEquipmentMaintenanceAction(
              equipmentId: item.id,
              notes:
                  'Completed standard felt ironing cycle with temperature plate.',
            ),
          );
        },
        icon: const Icon(Icons.iron, size: 14),
        label: const Text(
          'Log Ironing (Reset 50h)',
          style: TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else if (item.type == EquipmentType.cueTip) {
      return ElevatedButton.icon(
        onPressed: () {
          context.read<EquipmentBloc>().add(
            LogEquipmentMaintenanceAction(
              equipmentId: item.id,
              notes: 'All 12 house cues re-tipped with Elk Master 10mm tips.',
            ),
          );
        },
        icon: const Icon(Icons.build, size: 14),
        label: const Text('Log Re-Tipping', style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tableMaintenance,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () {
          context.read<EquipmentBloc>().add(
            LogEquipmentMaintenanceAction(
              equipmentId: item.id,
              notes: 'Automatic ball polishing machine cycle completed.',
            ),
          );
        },
        icon: const Icon(Icons.auto_fix_high, size: 14),
        label: const Text(
          'Mark Polished (Reset 30)',
          style: TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tableAvailable,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
  }
}
