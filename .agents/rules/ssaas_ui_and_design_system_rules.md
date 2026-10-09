# SSAAS UI, Themes & Design System Rules

These guidelines are mandatory for all UI and visual component modifications in SSAAS (`Constants.appName`).

## 1. Dark Obsidian Color System & Material 3 Theme

All views MUST strictly use design tokens defined in `AppColors` (`lib/core/theme/app_colors.dart`):

- **Backgrounds**: `AppColors.backgroundBase` (`0xFF0D0F12`) / `AppColors.cardSurface` (`0xFF161A20`).
- **Inputs & Controls**: `AppColors.inputSurface` (`0xFF212731`).
- **Borders & Dividers**: `AppColors.cardBorderStroke` (`0xFF2E3646`).
- **Primary Typography**: `AppColors.primaryText` (`0xFFF5F6F8`) - off-white for headers, timers, bills.
- **Secondary Typography**: `AppColors.secondaryText` (`0xFF9EA8B6`) - slate gray for subtexts and labels.
- **Brand Accent**: `AppColors.brandAccent` (`0xFF7C4DFF`) - electric purple for primary action buttons, POS actions, and highlighted states.
- **Table Matrix Status Indicators**:
  - Available: `AppColors.tableAvailable` (`0xFF00E676` - Emerald Green)
  - Occupied: `AppColors.tableOccupied` (`0xFFFF355E` - Neon Red)
  - Maintenance: `AppColors.tableMaintenance` (`0xFFFFC107` - Amber)
  - Reserved: `AppColors.tableReserved` (`0xFF29B6F6` - Sky Blue)

Never hardcode arbitrary hex colors or `Colors.white`/`Colors.black` for primary cards, backgrounds, or text.

## 2. Responsive Breakpoints & Adaptive Modals

Use the `Responsive` helper (`lib/core/utils/responsive.dart`):

- **Mobile Breakpoint**: `< 680.0` px (`Responsive.isMobile(context)`).
- **Tablet Breakpoint**: `>= 680.0` px and `< 1050.0` px (`Responsive.isTablet(context)`).
- **Desktop Breakpoint**: `>= 1050.0` px (`Responsive.isDesktop(context)`).

### Adaptive Modal Presentation
Whenever presenting dialogs or sheets, use `showAdaptiveModal`:
```dart
showAdaptiveModal<T>(
  context: context,
  builder: (ctx) => MyCustomDialog(),
);
```
- On **mobile (< 680px)**, this automatically renders a drag-enabled bottom sheet with keyboard padding handling.
- On **tablet & desktop (>= 680px)**, this renders a centered dialog.

## 3. Layout & RenderFlex Protection Rules

To eliminate Flutter yellow/black striped `RenderFlex overflow` exceptions:

1. **Modal Height Constraints**: Every modal dialog or bottom sheet MUST apply responsive height bounds and wrap scrollable content:
   ```dart
   constraints: BoxConstraints(
     maxHeight: MediaQuery.of(context).size.height * 0.9,
     maxWidth: 580,
   ),
   child: SingleChildScrollView(child: contentWidget),
   ```
2. **Dynamic Text Protection**: Never place unbounded dynamic strings or badge rows directly inside rigid `Row`s.
   - Always wrap in `Expanded(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis))` or `Flexible`.
   - For tags/badges that might wrap, use `Wrap(spacing: 8, runSpacing: 4, children: [...])`.
3. **Form Fields & Keyboards**: Wrap form dialogs in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))` to prevent keyboard overlap on mobile screens.

## 4. Input Formatting & Monetary Safety
All monetary text input fields (`TextField`, `TextFormField`) MUST enforce the decimal currency formatter:

```dart
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
]
```
- **Validation**: Disable confirm/submit buttons (`onPressed: null`) when monetary inputs are empty, zero, or exceed allowable limits (e.g., in due payment collection).

## 5. Screen Navigation & Tactile Feedback

- **Smooth Navigation**: Use `AppNavigation.pushSmooth(context, ScreenWidget())` (`lib/core/utils/app_navigation.dart`) for slide-and-fade screen transitions.
- **Haptic Feedback**: Use `AppHaptics` (`lib/core/utils/interactive_feedback.dart`):
  - `AppHaptics.selection()` for tab/filter switching.
  - `AppHaptics.light()` for card taps and button presses.
  - `AppHaptics.medium()` for match start/pause/resume.
  - `AppHaptics.success()` for completed match settlements and checkouts.
  - `AppHaptics.error()` for invalid entries or denied permissions.
