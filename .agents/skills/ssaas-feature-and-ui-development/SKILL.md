---
name: ssaas-feature-and-ui-development
description: >-
  Workflows, UI patterns, and step-by-step guidance for adding or modifying views, screens, modal dialogs, BLoC events, and reusable components in SSAAS (Constants.appName). Use when creating new UI features, building adaptive dialogs, integrating new BLoC states, or updating screen designs.
---

# SSAAS Feature & UI Development Guide

This skill documents the step-by-step workflow for creating or modifying UI screens, modal dialogs, custom components, and BLoC integrations in SSAAS (`Constants.appName`).

## 1. Architectural Workflow for New Features

When creating a new feature or extending an existing screen, follow this Clean Architecture workflow:

1. **Domain Model (`lib/domain/entities/`)**:
   - Create or extend immutable entity extending `Equatable`.
   - Implement `props`, `copyWith()`, `toMap()`, and `fromMap()`.
2. **Data Source Integration (`lib/data/datasources/firestore_service.dart`)**:
   - Add multi-tenant Firestore CRUD methods scoped by `companyId`.
   - Always call `trackRead`, `trackWrite`, or `trackDelete` for quota monitoring.
   - Use `SetOptions(merge: true)` on document updates.
3. **BLOC Events & State (`lib/presentation/blocs/<feature>/`)**:
   - Add strongly-typed event extending the feature's `*Event` class.
   - Add state properties with `copyWith` support in `*State`.
   - Implement event handler in `*Bloc`. Catch errors with `AppErrorHandler.format(e)`.
4. **UI Implementation (`lib/presentation/views/<feature>/`)**:
   - Consume BLoC using `BlocBuilder` or `BlocConsumer`.
   - Apply design system tokens from `AppColors` and `AppTheme`.
   - Use `Responsive.isMobile(context)` or `showAdaptiveModal` for layout adaptability.

---

## 2. Presenting Adaptive Modals & Dialogs

Always use `showAdaptiveModal` (`lib/core/utils/responsive.dart`):

```dart
Future<void> showMyFeatureDialog(BuildContext context) {
  return showAdaptiveModal<void>(
    context: context,
    builder: (ctx) => const _MyFeatureDialogContent(),
  );
}
```

### Dialog Content Structure:
```dart
class _MyFeatureDialogContent extends StatelessWidget {
  const _MyFeatureDialogContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 580,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header title with close button
              // Form fields with decimal formatters
              // Action buttons with AppHaptics feedback
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 3. UI Tokens & Styling Checklist

- **Background Card**: `AppColors.cardSurface` (`0xFF161A20`) with 1px border `AppColors.cardBorderStroke` (`0xFF2E3646`).
- **Input Fields**: `AppColors.inputSurface` (`0xFF212731`) with rounded corners (`10px`).
- **Primary Action Button**: `ElevatedButton` with `AppColors.brandAccent` (`0xFF7C4DFF`).
- **Text Styling**:
  - Title: `AppColors.primaryText` (`0xFFF5F6F8`), `FontWeight.bold` / `w600`.
  - Subtitle/Hint: `AppColors.secondaryText` (`0xFF9EA8B6`), `fontSize: 12-14`.
- **Haptic Trigger**: Call `AppHaptics.light()` or `AppHaptics.selection()` on interaction.
- **Screen Push**: Use `AppNavigation.pushSmooth(context, NewScreenView())`.

---

## 4. Common UI Pitfalls to Avoid

- **Unbounded Rows**: Never place dynamic text directly inside a `Row` without `Expanded` or `Flexible`.
- **Hardcoded Colors**: Avoid using `Colors.black`, `Colors.white`, or arbitrary hex codes. Use `AppColors`.
- **Direct `setState` for Core Data**: Do not store active match state or payment values in widget `setState()`. Use `FloorMatrixBloc` or `AuthBloc`.
- **Direct Global CLI Execution**: Always run `fvm flutter analyze` to verify code quality.
